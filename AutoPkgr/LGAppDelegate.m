//
//  LGAppDelegate.m
//  AutoPkgr
//
//  Created by James Barclay on 6/25/14.
//  Copyright (c) 2014 The Linde Group, Inc. All rights reserved.
//

#import "LGAppDelegate.h"
#import "LGConstants.h"
#import "LGConfigurationWindowController.h"

@implementation LGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Setup the status item
    [self setupStatusItem];

    if (![defaults boolForKey:kHasCompletedInitialSetup]) {
        [self showConfigurationWindow:nil];
        [defaults setObject:@YES forKey:kHasCompletedInitialSetup];
    }

    // Start the AutoPkg run timer if the user enabled it
    [self startAutoPkgRunTimer];

    // Update AutoPkg recipe repos when the application launches
    // if the user has enabled automatic repo updates
    if ([defaults boolForKey:kCheckForRepoUpdatesAutomaticallyEnabled]) {
        NSLog(@"Updating AutoPkg recipe repos.");
        [self updateAutoPkgRecipeReposInBackgroundAtAppLaunch];
    }
}

- (void)startAutoPkgRunTimer
{
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner startAutoPkgRunTimer];
}

- (void)updateAutoPkgRecipeReposInBackgroundAtAppLaunch
{
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner invokeAutoPkgRepoUpdateInBackgroundThread];
}

- (void)setupStatusItem
{
    // Setup the systemStatusBar
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setImage:[NSImage imageNamed:@"autopkgr.png"]];
    [self.statusItem setAlternateImage:[NSImage imageNamed:@"autopkgr_alt.png"]];
    [self.statusItem setHighlightMode:YES];
    self.statusItem.menu = self.statusMenu;
}

- (void)checkNowFromMenu:(id)sender
{
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner invokeAutoPkgInBackgroundThread];
}

- (void)showConfigurationWindow:(id)sender
{
    if (!self->configurationWindowController) {
        self->configurationWindowController = [[LGConfigurationWindowController alloc] initWithWindowNibName:@"LGConfigurationWindowController"];
    }

    [NSApp activateIgnoringOtherApps:YES];
    [self->configurationWindowController.window makeKeyAndOrderFront:nil];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults boolForKey:kWarnBeforeQuittingEnabled]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"Quit"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to quit %@?", kApplicationName]];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ will not be able to run AutoPkg in the background or send email notifications until you relaunch the application.", kApplicationName]];
        [alert setAlertStyle:NSWarningAlertStyle];

        if ([alert runModal] == NSAlertSecondButtonReturn) {
            NSLog(@"User cancelled quit.");
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
