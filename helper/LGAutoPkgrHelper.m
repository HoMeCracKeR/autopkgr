//
//  LGAutoPkgrHelper.m
//  AutoPkgr - Privileged Helper Tool
//
//  Created by Eldon Ahrold on 7/28/14.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "LGAutoPkgrHelper.h"
#import "LGAutoPkgrProtocol.h"
#import "LGAutoPkgr.h"
#import <AHLaunchCtl/AHLaunchCtl.h>
#import "AHCodesignVerifier.h"
#import "AHKeychain.h"

#import <pwd.h>
#import <syslog.h>
#import <SystemConfiguration/SystemConfiguration.h>

static const NSTimeInterval kHelperCheckInterval = 1.0; // how often to check whether to quit

@interface LGAutoPkgrHelper () <HelperAgent, NSXPCListenerDelegate>
@property (atomic, strong, readwrite) NSXPCListener *listener;
@property (weak) NSXPCConnection *connection;
@property (strong, nonatomic) NSMutableSet *connections;
@property (nonatomic, assign) BOOL helperToolShouldQuit;
@end

@implementation LGAutoPkgrHelper

- (id)init
{
    self = [super init];
    if (self) {
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kLGAutoPkgrHelperToolName];
        self->_listener.delegate = self;
    }
    return self;
}

- (void)run
{
    [self.listener resume];
    while (!self.helperToolShouldQuit) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kHelperCheckInterval]];
    }
}

#pragma mark - AutoPkgr Schedule
- (void)scheduleRun:(NSInteger)timer
               user:(NSString *)user
            program:(NSString *)program
      authorization:(NSData *)authData
              reply:(void (^)(NSError *error))reply
{

    // Display Authorization Prompt based on external form contained in
    // authData. If user cancels the challenge, or any other problem occurs
    // it will return a populated error object, with the details
    NSError *error = [LGAutoPkgrAuthorizer checkAuthorization:authData
                                                      command:_cmd];

    // If authorization was successful continue,
    if (!error) {
        // Check if the launch path and user are valid, and that the timer has a sensible mininum.
        if ([self launchPathIsValid:program error:&error] &&
            [self userIsValid:user error:&error] && timer >= 3600) {
            AHLaunchJob *job = [AHLaunchJob new];
            job.Program = program;
            job.Label = kLGAutoPkgrLaunchDaemonPlist;
            job.ProgramArguments = @[ program, @"-runInBackground", @"YES" ];
            job.StartInterval = timer;
            job.SessionCreate = YES;
            job.UserName = user;

            [[AHLaunchCtl sharedController] add:job toDomain:kAHGlobalLaunchDaemon error:&error];
        }
    }

    reply(error);
}

- (void)removeScheduleWithAuthorization:(NSData *)authData reply:(void (^)(NSError *))reply
{
    NSError *error = [LGAutoPkgrAuthorizer checkAuthorization:authData
                                                      command:_cmd];
    if (!error) {
        [[AHLaunchCtl sharedController] remove:kLGAutoPkgrLaunchDaemonPlist fromDomain:kAHGlobalLaunchDaemon error:&error];
    }

    reply(error);
}

- (BOOL)launchPathIsValid:(NSString *)path error:(NSError *__autoreleasing *)error;
{
    // Get the executable path of the helper tool.  We use this to compare against
    // the program the helper tool is asked add as the launchd.plist "Program" key
    NSString *helperExecPath = [[[NSProcessInfo processInfo] arguments] firstObject];
    return [AHCodesignVerifier codesignOfItemAtPath:path
                                 isSameAsItemAtPath:helperExecPath
                                              error:error];
}

- (BOOL)userIsValid:(NSString *)user error:(NSError *__autoreleasing *)error;
{
    // TODO: decide what criteria qualifies a valid user.
    // In future release we could potentially specify a user other
    // than the current logged in user to run the schedule as, but
    // we would need to check a number of criteria. For now just check
    // that the user matches the logged in (console) user.
    BOOL success = YES;
    NSString *loggedInUser = CFBridgingRelease(SCDynamicStoreCopyConsoleUser(NULL, NULL, NULL));
    syslog(LOG_INFO, "Checking that logged in user is the same as the user to run the shcedule as: %s", loggedInUser.UTF8String);

    if (!loggedInUser || !user || ![user isEqualToString:loggedInUser]) {
        if (error) {
            NSDictionary *errorDict = @{NSLocalizedDescriptionKey:@"Invalid user for scheduling autopkg run",
                                        NSLocalizedRecoverySuggestionErrorKey:@"There was a problem either verifying the user, or with the user's configuration. The user must be have a home directory set, a shell environment, and valid com.github.autopkg preferences."};
            *error = [NSError errorWithDomain:kLGApplicationName code:1 userInfo:errorDict];
        }
        success = NO;
    }

    return success;
}

#pragma mark - Life Cycle
- (void)quitHelper:(void (^)(BOOL success))reply
{
    // this will cause the run-loop to exit;
    // you should call it via NSXPCConnection
    // during the applicationShouldTerminate routine
    self.helperToolShouldQuit = YES;
    reply(YES);
}

- (void)installPackageFromPath:(NSString *)path
                 authorization:(NSData *)authData
                         reply:(void (^)(NSError *error))reply;
{
    NSError *error;

    error = [LGAutoPkgrAuthorizer checkAuthorization:authData command:_cmd];
    if (error != nil) {
        reply(error);
        return;
    }

    NSTask *task = [NSTask new];
    task.launchPath = @"/usr/sbin/installer";
    task.arguments = @[ @"-pkg", path, @"-target", @"/" ];
    task.standardError = [NSPipe pipe];

    [task launch];
    [task waitUntilExit];

    error = [LGError errorWithTaskError:task verb:kLGAutoPkgUndefinedVerb];

    reply(error);
}

- (void)uninstall:(NSData *)authData reply:(void (^)(NSError *))reply;
{
    NSError *error;
    error = [LGAutoPkgrAuthorizer checkAuthorization:authData command:_cmd];

    if (error) {
        return reply(error);
    }

    if (jobIsRunning(kLGAutoPkgrLaunchDaemonPlist, kAHGlobalLaunchDaemon)) {
        [[AHLaunchCtl sharedController] remove:kLGAutoPkgrLaunchDaemonPlist
                                    fromDomain:kAHGlobalLaunchDaemon
                                         error:nil];
    }

    [AHLaunchCtl removeFilesForHelperWithLabel:kLGAutoPkgrHelperToolName error:&error];
    reply(error);
    [AHLaunchCtl uninstallHelper:kLGAutoPkgrHelperToolName prompt:@"" error:nil];
}

//----------------------------------------
// Set up the one method of NSXPCListener
//----------------------------------------
- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
{

    newConnection.exportedObject = self;

    NSXPCInterface *exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperAgent)];
    newConnection.exportedInterface = exportedInterface;

    // Only accept the connection if the call is made by the console user.
    uid_t loggedInUser;
    SCDynamicStoreCopyConsoleUser(NULL, &loggedInUser, NULL);
    if (loggedInUser != newConnection.effectiveUserIdentifier) {
        return NO;
    }

    self.connection = newConnection;

    __weak typeof(newConnection) weakConnection = newConnection;
    // If all connections are invalidated on the remote side,
    // shutdown the helper.
    newConnection.invalidationHandler = ^() {
        __weak typeof(newConnection) strongConnection = weakConnection;
        [self.connections removeObject:strongConnection];
        if (!self.connections.count) {
            [self quitHelper:^(BOOL success) {}];
        }
    };

    [newConnection resume];
    [self.connections addObject:newConnection];

    return YES;
}
@end
