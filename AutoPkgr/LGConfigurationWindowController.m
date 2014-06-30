//
//  LGConfigurationWindowController.m
//  AutoPkgr
//
//  Created by James Barclay on 6/26/14.
//  Copyright (c) 2014 The Linde Group, Inc. All rights reserved.
//

#import "LGConfigurationWindowController.h"
#import "LGConstants.h"
#import "LGEmailer.h"
#import "LGHostInfo.h"
#import "LGUnzipper.h"
#import "SSKeychain.h"

@interface LGConfigurationWindowController ()

@end

@implementation LGConfigurationWindowController

@synthesize smtpTo;
@synthesize smtpServer;
@synthesize smtpUsername;
@synthesize smtpPassword;
@synthesize smtpPort;
@synthesize smtpAuthenticationEnabledButton;
@synthesize smtpTLSEnabledButton;
@synthesize warnBeforeQuittingButton;
@synthesize gitStatusLabel;
@synthesize autoPkgStatusLabel;
@synthesize gitStatusIcon;
@synthesize autoPkgStatusIcon;
@synthesize scheduleMatrix;

- (void)awakeFromNib
{
    // This is for the token field support
    [self.smtpTo setDelegate:self];

    [smtpAuthenticationEnabledButton addObserver:self
                                      forKeyPath:@"cell.state"
                                         options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                         context:NULL];
}

- (void)dealloc
{
    [smtpAuthenticationEnabledButton removeObserver:self forKeyPath:@"cell.state"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    NSLog(@"Keypath: %@", keyPath);
//    NSLog(@"ofObject: %@", object);
//    NSLog(@"change: %@", change);
    if ([keyPath isEqualToString:@"cell.state"]) {
        if ([[change objectForKey:@"new"] integerValue] == 1) {
            [smtpUsername setEnabled:YES];
            [smtpPassword setEnabled:YES];
        } else {
            [smtpUsername setEnabled:NO];
            [smtpPassword setEnabled:NO];
        }
    }
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.

    // Set matrix size (IB effs this up)
    [scheduleMatrix setIntercellSpacing:NSMakeSize(10.0, 10.5)];

    // Populate the SMTP settings from the user defaults if they exist
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults objectForKey:kSMTPServer]) {
        [smtpServer setStringValue:[defaults objectForKey:kSMTPServer]];
    }
    if ([defaults integerForKey:kSMTPPort]) {
        [smtpPort setIntegerValue:[defaults integerForKey:kSMTPPort]];
    }
    if ([defaults objectForKey:kSMTPUsername]) {
        [smtpUsername setStringValue:[defaults objectForKey:kSMTPUsername]];
    }
    if ([defaults objectForKey:kSMTPTo]) {
        NSMutableArray *to = [[NSMutableArray alloc] init];
        for (NSString *toAddress in [defaults objectForKey:kSMTPTo]) {
            if (![toAddress isEqual:@""]) {
                [to addObject:toAddress];
            }
        }
        [smtpTo setObjectValue:to];
    }
    if ([defaults objectForKey:kSMTPTLSEnabled]) {
        [smtpTLSEnabledButton setState:[[defaults objectForKey:kSMTPTLSEnabled] boolValue]];
    }
    if ([defaults objectForKey:kSMTPAuthenticationEnabled]) {
        [smtpAuthenticationEnabledButton setState:[[defaults objectForKey:kSMTPAuthenticationEnabled] boolValue]];
    }
    if ([defaults objectForKey:kWarnBeforeQuittingEnabled]) {
        [warnBeforeQuittingButton setState:[[defaults objectForKey:kWarnBeforeQuittingEnabled] boolValue]];
    }

    // Read the SMTP password from the keychain and populate in NSSecureTextField
    NSError *error = nil;
    NSString *password = [SSKeychain passwordForService:kApplicationName account:[defaults objectForKey:kSMTPUsername] error:&error];

    if ([error code] == SSKeychainErrorNotFound) {
        NSLog(@"Password not found for account %@.", [defaults objectForKey:kSMTPUsername]);
    } else {
        // Only populate the SMTP Password field if the username exists
        if (![[defaults objectForKey:kSMTPUsername] isEqual:@""]) {
            NSLog(@"Retrieved password from keychain for account %@.", [defaults objectForKey:kSMTPUsername]);
            [smtpPassword setStringValue:password];
        }
    }

    // Create an instance of the LGHostInfo class
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];

    // Set the SMTPFrom key to shortname@hostname
    [defaults setObject:[hostInfo getUserAtHostName] forKey:kSMTPFrom];

    if ([hostInfo gitInstalled]) {
        [gitStatusLabel setStringValue:@"Git has been installed."];
        [gitStatusIcon setImage:[NSImage imageNamed:@"status-available.tiff"]];
    } else {
        [gitStatusLabel setStringValue:@"Git is not installed."];
        [gitStatusIcon setImage:[NSImage imageNamed:@"status-unavailable.tiff"]];
    }

    if ([hostInfo autoPkgInstalled]) {
        [autoPkgStatusLabel setStringValue:@"AutoPkg has been installed."];
        [autoPkgStatusIcon setImage:[NSImage imageNamed:@"status-available.tiff"]];
    } else {
        [autoPkgStatusLabel setStringValue:@"AutoPkg is not installed."];
        [autoPkgStatusIcon setImage:[NSImage imageNamed:@"status-unavailable.tiff"]];
    }

    // Synchronize with the defaults database
    [defaults synchronize];
}

- (IBAction)sendTestEmail:(id)sender {
    // Send a test email notification when the user
    // clicks "Send Test Email"

    // Create an instance of the LGEmailer class
    LGEmailer *emailer = [[LGEmailer alloc] init];

    // Send the test email notification by sending the
    // sendTestEmail message to our object
    [emailer sendTestEmail];
}

- (IBAction)saveAndClose:(id)sender {
    // Store the SMTP settings in NSUserDefaults
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Create an instance of the LGHostInfo class
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];

    [defaults setObject:[smtpServer stringValue] forKey:kSMTPServer];
    [defaults setInteger:[smtpPort integerValue]forKey:kSMTPPort];
    [defaults setObject:[smtpUsername stringValue] forKey:kSMTPUsername];
    [defaults setObject:[hostInfo getUserAtHostName] forKey:kSMTPFrom];
    [defaults setBool:YES forKey:kHasCompletedInitialSetup];
    // We use objectValue here because objectValue returns an
    // array of strings if the field contains a series of strings
    [defaults setObject:[smtpTo objectValue] forKey:kSMTPTo];

    if ([smtpTLSEnabledButton state] == NSOnState) {
        // The user wants to enable TLS for this SMTP configuration
        NSLog(@"Enabling TLS.");
        [defaults setBool:YES forKey:kSMTPTLSEnabled];
    } else {
        // The user wants to disable TLS for this SMTP configuration
        NSLog(@"Disabling TLS.");
        [defaults setBool:NO forKey:kSMTPTLSEnabled];
    }

    if ([warnBeforeQuittingButton state] == NSOnState) {
        NSLog(@"Enabling warning before quitting.");
        [defaults setBool:YES forKey:kWarnBeforeQuittingEnabled];
    } else {
        NSLog(@"Disabling warning before quitting.");
        [defaults setBool:NO forKey:kWarnBeforeQuittingEnabled];
    }

    if ([smtpAuthenticationEnabledButton state] == NSOnState) {
        NSLog(@"Enabling SMTP authentication.");
        [defaults setBool:YES forKey:kSMTPAuthenticationEnabled];
    } else {
        NSLog(@"Disabling SMTP authentication.");
        [defaults setBool:NO forKey:kSMTPAuthenticationEnabled];
    }

    // Store the password used for SMTP authentication in the default keychain
    [SSKeychain setPassword:[smtpPassword stringValue] forService:kApplicationName account:[smtpUsername stringValue]];

    // Synchronize with the defaults database
    [defaults synchronize];

    // Close the window
    [self close];
}

- (void)runCommandAsRoot
{
    // Super dirty hack, but way easier than
    // using Authorization Services
    NSDictionary *error = [[NSDictionary alloc] init];
    NSString *script =  @"do shell script \"whoami > /tmp/me\" with administrator privileges";
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    if ([appleScript executeAndReturnError:&error]) {
        NSLog(@"Authorization successful!");
    } else {
        NSLog(@"Authorization failed!");
    }
}

/*
 This should prompt for Xcode CLI tools
 installation on systems without Git.
 */
- (IBAction)installGit:(id)sender {
    NSTask *task = [[NSTask alloc] init];
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *installGitFileHandle = [pipe fileHandleForReading];
    NSString *gitCmd = @"git";

    [task setLaunchPath:gitCmd];
    [task setArguments:[NSArray arrayWithObjects:@"--version", nil]];
    [task setStandardError:pipe];
    [task launch];
    [installGitFileHandle readInBackgroundAndNotify];
}

- (void)downloadAutoPkg
{
    LGUnzipper *unzipper = [[LGUnzipper alloc] init];
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"autopkg.zip"];
    NSLog(@"tmpPath: %@", tmpPath);
    NSData *autoPkg = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:kAutoPkgDownloadURL]];
    [autoPkg writeToFile:tmpPath atomically:YES];
    BOOL autoPkgUnzipped = [unzipper unzip:tmpPath targetDir:[NSTemporaryDirectory() stringByAppendingPathComponent:@"autopkg"]];

    if (autoPkgUnzipped) {
        NSLog(@"Successfully unzipped AutoPkg!");
    } else {
        NSLog(@":(");
    }
}

- (IBAction)installAutoPkg:(id)sender {
    // Get authorization
    // Download AutoPkg zipball from https://github.com/autopkg/autopkg/zipball/master
    // Store zip in /tmp
    // Unzip AutoPkg, then run Scripts/install.sh as root
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(downloadAutoPkg)
                                        object:nil];
    [queue addOperation:operation];

    [self runCommandAsRoot];
}

@end
