//
//  LGAutoPkgSchedule.m
//  AutoPkgr
//
//  Created by Eldon on 9/6/14.
//
//  Copyright 2014-2015 The Linde Group, Inc.
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

#import "LGAutoPkgSchedule.h"
#import "LGAutoPkgr.h"
#import "LGAutoPkgrHelperConnection.h"
#import <AHLaunchCtl/AHLaunchCtl.h>

NSString *const kLGLaunchedAtLogin = @"LaunchedAtLogin";

@implementation LGAutoPkgSchedule

+ (void)startAutoPkgSchedule:(BOOL)start interval:(NSInteger)interval isForced:(BOOL)forced reply:(void (^)(NSError *error))reply;
{
    BOOL scheduleIsRunning = jobIsRunning(kLGAutoPkgrLaunchDaemonPlist, kAHGlobalLaunchDaemon);
    if (start && interval == 0) {
        reply([LGError errorWithCode:kLGErrorIncorrectScheduleTimerInterval]);
        return;
    }

    // Create the external form authorization data for the helper
    NSData *authorization = [LGAutoPkgrAuthorizer authorizeHelper];
    assert(authorization != nil);

    LGAutoPkgrHelperConnection *helper = [LGAutoPkgrHelperConnection new];
    [helper connectToHelper];

    if (start && (!scheduleIsRunning || forced)) {
        // Convert seconds to hours for our time interval
        NSTimeInterval runInterval = interval * 60 * 60;
        NSString *program = [[NSProcessInfo processInfo] arguments].firstObject;

        [[helper.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            reply(error);
        }] scheduleRun:runInterval
                     user:NSUserName()
                  program:program
            authorization:authorization
                    reply:^(NSError *error) {
                        if (!error) {
                            NSDate *date = [NSDate dateWithTimeIntervalSinceNow:runInterval];
                            NSDateFormatter *fomatter = [NSDateFormatter new];
                            [fomatter setDateStyle:NSDateFormatterMediumStyle];
                            [fomatter setTimeStyle:NSDateFormatterMediumStyle];
                            NSLog(@"Next scheduled AutoPkg run will occur at %@",[fomatter stringFromDate:date]);
                        }
                        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
                        reply(error);
                    }];
    } else if (scheduleIsRunning) {
        [[helper.connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
            reply(error);
        }] removeScheduleWithAuthorization:authorization
                                      reply:^(NSError *error) {
                                          [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
                                        reply(error);
                                      }];
    }
}

+ (BOOL)updateAppsIsScheduled:(NSInteger *)scheduleInterval
{
    AHLaunchJob *job = [AHLaunchCtl jobFromFileNamed:kLGAutoPkgrLaunchDaemonPlist inDomain:kAHGlobalLaunchDaemon];

    NSInteger interval = (job.StartInterval == 0) ? 24 : job.StartInterval / 60 / 60;
    if (scheduleInterval) {
        *scheduleInterval = interval;
    }
    return job ? YES : NO;
}

+ (BOOL)launchAtLogin:(BOOL)launch
{
    NSBundle *appBundle = [NSBundle mainBundle];
    NSString *launchAgentFileName = [appBundle.bundleIdentifier stringByAppendingPathExtension:@"launcher.plist"];

    NSString *launchAgentPath = [[@"~/Library/LaunchAgents" stringByAppendingPathComponent:launchAgentFileName] stringByExpandingTildeInPath];

    AHLaunchJob *job = [AHLaunchJob new];
    job.Label = [launchAgentFileName stringByDeletingPathExtension];

    // Set an extra argument here to when launched at login, so the app delegate
    // knows to defer launching the configuration window once.
    job.ProgramArguments = @[ appBundle.executablePath, kLGLaunchedAtLogin ];
    job.RunAtLoad = YES;

    if (launch) {
        return [job.dictionary writeToFile:launchAgentPath atomically:YES];
    } else {
        return [[NSFileManager defaultManager] removeItemAtPath:launchAgentPath error:nil];
    }
}

+ (BOOL)willLaunchAtLogin
{
    AHLaunchJob *job = [AHLaunchCtl jobFromFileNamed:@"com.lindegroup.AutoPkgr.launcher.plist" inDomain:kAHUserLaunchAgent];
    return ([job.ProgramArguments.firstObject isEqualToString:[[NSBundle mainBundle] executablePath]]);
}

@end
