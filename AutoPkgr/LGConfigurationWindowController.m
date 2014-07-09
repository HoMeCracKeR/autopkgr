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
#import "LGAutoPkgRunner.h"
#import "SSKeychain.h"

@interface LGConfigurationWindowController ()

@end

@implementation LGConfigurationWindowController

@synthesize smtpTo;
@synthesize smtpServer;
@synthesize smtpUsername;
@synthesize smtpPassword;
@synthesize smtpPort;
@synthesize repoURLToAdd;
@synthesize smtpAuthenticationEnabledButton;
@synthesize smtpTLSEnabledButton;
@synthesize warnBeforeQuittingButton;
@synthesize checkForNewVersionsOfAppsAutomaticallyButton;
@synthesize checkForRepoUpdatesAutomaticallyButton;
@synthesize sendEmailNotificationsWhenNewVersionsAreFoundButton;
@synthesize autoPkgCacheFolderButton;
@synthesize autoPkgRecipeReposFolderButton;
@synthesize localMunkiRepoFolderButton;
@synthesize gitStatusLabel;
@synthesize autoPkgStatusLabel;
@synthesize gitStatusIcon;
@synthesize autoPkgStatusIcon;
@synthesize scheduleMatrix;

static void *XXCheckForNewAppsAutomaticallyEnabledContext = &XXCheckForNewAppsAutomaticallyEnabledContext;
static void *XXCheckForRepoUpdatesAutomaticallyEnabledContext = &XXCheckForRepoUpdatesAutomaticallyEnabledContext;
static void *XXEmailNotificationsEnabledContext = &XXEmailNotificationsEnabledContext;
static void *XXAuthenticationEnabledContext = &XXAuthenticationEnabledContext;

- (void)awakeFromNib
{
    // This is for the token field support
    [self.smtpTo setDelegate:self];

    [smtpAuthenticationEnabledButton addObserver:self
                                      forKeyPath:@"cell.state"
                                         options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                         context:XXAuthenticationEnabledContext];

    [sendEmailNotificationsWhenNewVersionsAreFoundButton addObserver:self
                                                          forKeyPath:@"cell.state"
                                                             options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                                                             context:XXEmailNotificationsEnabledContext];
}

- (void)dealloc
{
    [smtpAuthenticationEnabledButton removeObserver:self forKeyPath:@"cell.state" context:XXAuthenticationEnabledContext];
    [sendEmailNotificationsWhenNewVersionsAreFoundButton removeObserver:self forKeyPath:@"cell.state" context:XXEmailNotificationsEnabledContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
//    NSLog(@"Keypath: %@", keyPath);
//    NSLog(@"ofObject: %@", object);
//    NSLog(@"change: %@", change);
    if (context == XXAuthenticationEnabledContext) {
        if ([keyPath isEqualToString:@"cell.state"]) {
            if ([[change objectForKey:@"new"] integerValue] == 1) {
                [smtpUsername setEnabled:YES];
                [smtpPassword setEnabled:YES];
            } else {
                [smtpUsername setEnabled:NO];
                [smtpPassword setEnabled:NO];
            }
        }
    } else if (context == XXEmailNotificationsEnabledContext) {
        if ([keyPath isEqualToString:@"cell.state"]) {
            if ([[change objectForKey:@"new"] integerValue] == 1) {
                [smtpTo setEnabled:YES];
                [smtpServer setEnabled:YES];
                [smtpUsername setEnabled:YES];
                [smtpPassword setEnabled:YES];
                [smtpPort setEnabled:YES];
                [smtpAuthenticationEnabledButton setEnabled:YES];
                [smtpTLSEnabledButton setEnabled:YES];
            } else {
                [smtpTo setEnabled:NO];
                [smtpServer setEnabled:NO];
                [smtpUsername setEnabled:NO];
                [smtpPassword setEnabled:NO];
                [smtpPort setEnabled:NO];
                [smtpAuthenticationEnabledButton setEnabled:NO];
                [smtpTLSEnabledButton setEnabled:NO];
            }
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
        [gitStatusLabel setStringValue:kGitInstalledLabel];
        [gitStatusIcon setImage:[NSImage imageNamed:kStatusAvailableImage]];
    } else {
        [gitStatusLabel setStringValue:kGitNotInstalledLabel];
        [gitStatusIcon setImage:[NSImage imageNamed:kStatusUnavailableImage]];
    }

    if ([hostInfo autoPkgInstalled]) {
        [autoPkgStatusLabel setStringValue:kAutoPkgInstalledLabel];
        [autoPkgStatusIcon setImage:[NSImage imageNamed:kStatusAvailableImage]];
    } else {
        [autoPkgStatusLabel setStringValue:kAutoPkgNotInstalledLabel];
        [autoPkgStatusIcon setImage:[NSImage imageNamed:kStatusUnavailableImage]];
    }

    // Enable tools buttons if directories exist
    BOOL isDir;
    NSString *autoPkgCacheFolder = [hostInfo getAutoPkgCacheDir];
    NSString *autoPkgRecipeReposFolder = [hostInfo getAutoPkgRecipeReposDir];
    NSString *localMunkiRepoFolder = [hostInfo getMunkiRepoDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgCacheFolder isDirectory:&isDir] && isDir) {
        [autoPkgCacheFolderButton setEnabled:YES];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgRecipeReposFolder isDirectory:&isDir] && isDir) {
        [autoPkgRecipeReposFolderButton setEnabled:YES];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:localMunkiRepoFolder isDirectory:&isDir] && isDir) {
        [localMunkiRepoFolderButton setEnabled:YES];
    }

    // Synchronize with the defaults database
    [defaults synchronize];
}

- (BOOL)createDirectoryAtPath:(NSString *)resolvedPath withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError *__autoreleasing *)error
{
    BOOL isDir;
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm createDirectoryAtPath:resolvedPath withIntermediateDirectories:createIntermediates attributes:attributes error:error];

    if ([fm fileExistsAtPath:resolvedPath isDirectory:&isDir] && isDir) {
        return YES;
    }

    return NO;
}

- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory
                           inDomain:(NSSearchPathDomainMask)domainMask
                appendPathComponent:(NSString *)appendComponent
                              error:(NSError **)errorOut
{
    // Search for the path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory,
                                                         domainMask,
                                                         YES);
    if ([paths count] == 0) {
        return nil;
    }

    // Normally only need the first path
    NSString *resolvedPath = [paths objectAtIndex:0];

    if (appendComponent) {
        resolvedPath = [resolvedPath
                        stringByAppendingPathComponent:appendComponent];
    }

    // Create the path if it doesn't exist
    NSError *error;
    BOOL success = [self createDirectoryAtPath:resolvedPath
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&error];
    if (!success) {
        if (errorOut) {
            *errorOut = error;
        }

        return nil;
    }
    
    // If we've made it this far, we have succeeded
    if (errorOut) {
        *errorOut = nil;
    }

    return resolvedPath;
}

- (NSString *)applicationSupportDirectory
{
    NSString *executableName =
    [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSError *error;
    NSString *result = [self findOrCreateDirectory:NSApplicationSupportDirectory
                                          inDomain:NSUserDomainMask
                               appendPathComponent:executableName
                                             error:&error];
    if (error) {
        NSLog(@"Unable to find or create application support directory:\n%@", error);
    }

    return result;
}

- (void)runAutoPkgWithRecipeList:(NSString *)recipeListPath
{

}

- (void)createRecipeListFromArrayOfRecipes:(NSArray *)recipes inDirectory:(NSString *)dir
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSString *recipeListFilePath = [NSString stringWithFormat:@"%@/recipe_list.txt", dir];
    NSLog(@"recipeListFilePath: %@.", recipeListFilePath);

    // Remove the file if it already exists (start fresh
    // every time the user saves)
    if ([fm fileExistsAtPath:recipeListFilePath]) {
        [fm removeItemAtPath:recipeListFilePath error:&error];
        if (error) {
            NSLog(@"Unable to remove existing recipe list at %@. Error: %@.", recipeListFilePath, error);
        }
    }

    NSString *recipeStringsSeparatedByNewLines = [recipes componentsJoinedByString:@"\n"];
    [recipeStringsSeparatedByNewLines writeToFile:recipeListFilePath atomically:NO encoding:NSUTF8StringEncoding error:&error];

    if (error) {
        NSLog(@"Unable to write the AutoPkg recipe list to a file at %@. Error: %@. Recipes: %@\n", recipeListFilePath, error, recipeStringsSeparatedByNewLines);
    }
}

- (NSArray *)tempAutoPkgRecipesToRun // TODO: Remove me, (should get results from table view)
{
    return [NSArray arrayWithObjects:@"Firefox.pkg", @"GoogleChrome.pkg", @"Evernote.pkg", nil];
}

- (IBAction)sendTestEmail:(id)sender
{
    // Send a test email notification when the user
    // clicks "Send Test Email"

    // Create an instance of the LGEmailer class
    LGEmailer *emailer = [[LGEmailer alloc] init];

    // Send the test email notification by sending the
    // sendTestEmail message to our object
    [emailer sendTestEmail];
}

- (IBAction)saveAndClose:(id)sender
{
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

- (void)runCommandAsRoot:(NSString *)runDirectory command:(NSString *)command
{
    // Get the current working directory
    NSString *bundlePath = [[NSBundle mainBundle] bundlePath];

    // Change the path to the AutoPkg directory
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:runDirectory];

    // Super dirty hack, but way easier than
    // using Authorization Services
    NSDictionary *error = [[NSDictionary alloc] init];
    NSString *script = [NSString stringWithFormat:@"do shell script \"sh -c '%@'\" with administrator privileges", command];
    NSLog(@"appleScript commands: %@", script);
    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:script];
    if ([appleScript executeAndReturnError:&error]) {
        NSLog(@"Authorization successful!");
    } else {
        NSLog(@"Authorization failed! Error: %@.", error);
    }

    // Change back to the bundle path when we're done
    [[NSFileManager defaultManager] changeCurrentDirectoryPath:bundlePath];
}

/*
 This should prompt for Xcode CLI tools
 installation on systems without Git.
 */
- (IBAction)installGit:(id)sender
{
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

- (void)downloadAndInstallAutoPkg
{
    LGUnzipper *unzipper = [[LGUnzipper alloc] init];
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSError *error;

    // Get paths for autopkg.zip and expansion directory
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"autopkg.zip"];
    NSString *autoPkgTmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"autopkg"];

    // Download AutoPkg to temp directory
    NSData *autoPkg = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:kAutoPkgDownloadURL]];
    [autoPkg writeToFile:tmpPath atomically:YES];

    // Unzip AutoPkg from the temp directory
    BOOL autoPkgUnzipped = [unzipper unzip:tmpPath targetDir:autoPkgTmpPath];
    if (autoPkgUnzipped) {
        NSLog(@"Successfully unzipped AutoPkg!");
    } else {
        NSLog(@"Couldn't unzip AutoPkg :(");
    }

    // Get the AutoPkg run directory and script path
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:autoPkgTmpPath error:&error];

    if (error) {
        NSLog(@"An error occurred when attempting to get the contents of the directory %@. Error: %@", autoPkgTmpPath, error);
    }

    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self BEGINSWITH 'autopkg-autopkg-'"];
    NSArray *autoPkgDir = [dirContents filteredArrayUsingPredicate:fltr];
    NSString *autoPkgPath = [autoPkgTmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", [autoPkgDir objectAtIndex:0]]];
    NSString *autoPkgInstallScriptPath = [NSString stringWithFormat:@"%@/Scripts/install.sh", autoPkgPath];

    // Run the AutoPkg installer script as root
    [self runCommandAsRoot:autoPkgPath command:autoPkgInstallScriptPath];

    // Update the autoPkgStatus icon and label if it installed successfully
    if ([hostInfo autoPkgInstalled]) {
        NSLog(@"AutoPkg installed successfully!");
        [autoPkgStatusLabel setStringValue:kAutoPkgInstalledLabel];
        [autoPkgStatusIcon setImage:[NSImage imageNamed:kStatusAvailableImage]];
    }
}

- (IBAction)installAutoPkg:(id)sender
{
    // Download and install AutoPkg on a background thread
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSInvocationOperation *operation = [[NSInvocationOperation alloc]
                                        initWithTarget:self
                                        selector:@selector(downloadAndInstallAutoPkg)
                                        object:nil];
    [queue addOperation:operation];
}

- (IBAction)openAutoPkgCacheFolder:(id)sender
{
    BOOL isDir;
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSString *autoPkgCacheFolder = [hostInfo getAutoPkgCacheDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgCacheFolder isDirectory:&isDir] && isDir) {
        NSURL *autoPkgCacheFolderURL = [NSURL fileURLWithPath:autoPkgCacheFolder];
        [[NSWorkspace sharedWorkspace] openURL:autoPkgCacheFolderURL];
    } else {
        NSLog(@"%@ does not exist.", autoPkgCacheFolder);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot find the AutoPkg Cache folder."];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ could not find the AutoPkg Cache folder located in %@. Please verify that this folder exists.", kApplicationName, autoPkgCacheFolder]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
}

- (IBAction)openAutoPkgRecipeReposFolder:(id)sender
{
    BOOL isDir;
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSString *autoPkgRecipeReposFolder = [hostInfo getAutoPkgRecipeReposDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:autoPkgRecipeReposFolder isDirectory:&isDir] && isDir) {
        NSURL *autoPkgRecipeReposFolderURL = [NSURL fileURLWithPath:autoPkgRecipeReposFolder];
        [[NSWorkspace sharedWorkspace] openURL:autoPkgRecipeReposFolderURL];
    } else {
        NSLog(@"%@ does not exist.", autoPkgRecipeReposFolder);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot find the AutoPkg RecipeRepos folder."];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ could not find the AutoPkg RecipeRepos folder located in %@. Please verify that this folder exists.", kApplicationName, autoPkgRecipeReposFolder]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
}

- (IBAction)openLocalMunkiRepoFolder:(id)sender
{
    BOOL isDir;
    LGHostInfo *hostInfo = [[LGHostInfo alloc] init];
    NSString *localMunkiRepoFolder = [hostInfo getMunkiRepoDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:localMunkiRepoFolder isDirectory:&isDir] && isDir) {
        NSURL *localMunkiRepoFolderURL = [NSURL fileURLWithPath:localMunkiRepoFolder];
        [[NSWorkspace sharedWorkspace] openURL:localMunkiRepoFolderURL];
    } else {
        NSLog(@"%@ does not exist.", localMunkiRepoFolder);
        NSAlert *alert = [[NSAlert alloc] init];
        [alert addButtonWithTitle:@"OK"];
        [alert setMessageText:@"Cannot find the Munki Repository."];
        [alert setInformativeText:[NSString stringWithFormat:@"%@ could not find the Munki repository located in %@. Please verify that this folder exists.", kApplicationName, localMunkiRepoFolder]];
        [alert setAlertStyle:NSWarningAlertStyle];
        [alert runModal];
    }
}

- (IBAction)addAutoPkgRepoURL:(id)sender
{
    // TODO: Input validation + success/failure notification
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner addAutoPkgRecipeRepo:[repoURLToAdd stringValue]];
}

- (IBAction)updateReposNow:(id)sender
{
    // TODO: Success/failure notification
    NSLog(@"Updating AutoPkg recipe repos.");
    LGAutoPkgRunner *autoPkgRunner = [[LGAutoPkgRunner alloc] init];
    [autoPkgRunner updateAutoPkgRecipeRepos];
}

- (IBAction)checkAppsNow:(id)sender
{
    NSLog(@"Creating Application Support directory for %@.", kApplicationName);
    NSString *applicationSupportDirectory = [self applicationSupportDirectory];
    NSLog(@"Application Support directory is %@.", applicationSupportDirectory);
    NSLog(@"Creating a recipe list.");
    [self createRecipeListFromArrayOfRecipes:[self tempAutoPkgRecipesToRun] inDirectory:applicationSupportDirectory];
}

@end
