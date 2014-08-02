//
//  LGHostInfo.m
//  AutoPkgr
//
//  Created by James Barclay on 6/27/14.
//  Copyright (c) 2014 The Linde Group, Inc. All rights reserved.
//

#import "LGHostInfo.h"
#import "LGConstants.h"

@implementation LGHostInfo

- (NSString *)getUserName
{
    return NSUserName();
}

- (NSString *)getHostName
{
    return [[NSHost currentHost] name];
}

- (NSString *)getUserAtHostName
{
    NSString *userAtHostName = [NSString stringWithFormat:@"%@@%@", [self getUserName], [self getHostName]];

    return userAtHostName;
}

- (NSString *)getAutoPkgRecipeOverridesDir
{
    NSString *autoPkgRecipeOverridesFolderFromPrefs = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("RECIPE_OVERRIDE_DIRS"), CFSTR("com.github.autopkg"));

    if (!autoPkgRecipeOverridesFolderFromPrefs) {
        NSString *autoPkgRecipeOverridesFolder = [NSString stringWithFormat:@"%@/Library/AutoPkg/RecipeOverrides", NSHomeDirectory()];
        NSLog(@"RECIPE_OVERRIDE_DIRS is not specified in the com.github.autopkg preference domain. Using the default value of %@ instead.", autoPkgRecipeOverridesFolder);
        return autoPkgRecipeOverridesFolder;
    }

    return autoPkgRecipeOverridesFolderFromPrefs;
}

- (NSString *)getAutoPkgCacheDir
{
    NSString *autoPkgCacheFolderFromPrefs = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("CACHE_DIR"), CFSTR("com.github.autopkg"));

    if (!autoPkgCacheFolderFromPrefs) {
        NSString *autoPkgCacheFolder = [NSString stringWithFormat:@"%@/Library/AutoPkg/Cache", NSHomeDirectory()];
        NSLog(@"CACHE_DIR is not specified in the com.github.autopkg preference domain. Using the default path of %@ instead.", autoPkgCacheFolder);
        return autoPkgCacheFolder;
    }

    return autoPkgCacheFolderFromPrefs;
}

- (NSString *)getAutoPkgRecipeReposDir
{
    NSString *autoPkgRecipeReposFolderFromPrefs = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("RECIPE_REPO_DIR"), CFSTR("com.github.autopkg"));

    if (!autoPkgRecipeReposFolderFromPrefs) {
        NSString *autoPkgRecipeReposFolder = [NSString stringWithFormat:@"%@/Library/AutoPkg/RecipeRepos", NSHomeDirectory()];
        NSLog(@"RECIPE_REPO_DIR is not specified in the com.github.autopkg preference domain. Using the default path of %@ instead.", autoPkgRecipeReposFolder);
        return autoPkgRecipeReposFolder;
    }

    return autoPkgRecipeReposFolderFromPrefs;
}

- (NSString *)getMunkiRepoDir
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (![defaults objectForKey:kLocalMunkiRepoPath]) {
        NSLog(@"Unable to find local Munki repo path in user defaults.");
        NSString *localMunkiRepoFolderFromAutoPkgPrefs = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("MUNKI_REPO"), CFSTR("com.github.autopkg"));
        NSString *localMunkiRepoFolderFromMunkiPrefs = (__bridge_transfer NSString *)CFPreferencesCopyAppValue(CFSTR("repo_path"), CFSTR("com.googlecode.munki.munkiimport"));

        if (!localMunkiRepoFolderFromAutoPkgPrefs) {

            if (!localMunkiRepoFolderFromMunkiPrefs) {
                NSString *localMunkiRepoFolder = @"/Users/Shared/munki_repo";
                NSLog(@"MUNKI_REPO is not specified in the com.github.autopkg or com.googlecode.munki.munkiimport preference domains. Using the default path of %@ instead.", localMunkiRepoFolder);
                return localMunkiRepoFolder;
            }

            return localMunkiRepoFolderFromMunkiPrefs;
        }

        return localMunkiRepoFolderFromAutoPkgPrefs;
    }

    return [defaults objectForKey:kLocalMunkiRepoPath];
}

- (BOOL)gitInstalled
{
    NSArray *knownGitPaths = [[NSArray alloc] initWithObjects:@"/usr/bin/git", @"/usr/local/bin/git", @"/opt/boxen/homebrew/bin/git", nil];

    for (NSString *path in knownGitPaths) {
        if ([[NSFileManager defaultManager] isExecutableFileAtPath:path]) {
            return YES;
        }
    }

    return NO;
}

- (NSString *)getAutoPkgVersion
{
    NSTask *getAutoPkgVersionTask = [[NSTask alloc] init];
    NSPipe *getAutoPkgVersionPipe = [NSPipe pipe];
    NSFileHandle *fileHandle = [getAutoPkgVersionPipe fileHandleForReading];

    NSString *launchPath = @"/usr/bin/python";
    NSArray *args = [NSArray arrayWithObjects:@"/usr/local/bin/autopkg", @"version", nil];

    [getAutoPkgVersionTask setLaunchPath:launchPath];
    [getAutoPkgVersionTask setArguments:args];
    [getAutoPkgVersionTask setStandardOutput:getAutoPkgVersionPipe];
    [getAutoPkgVersionTask setStandardError:getAutoPkgVersionPipe];

    [getAutoPkgVersionTask launch];
    [getAutoPkgVersionTask waitUntilExit];

    NSData *autoPkgVersionData = [fileHandle readDataToEndOfFile];
    NSString *autoPkgVersionString = [[NSString alloc] initWithData:autoPkgVersionData encoding:NSUTF8StringEncoding];
    NSString *trimmedVersionString = [autoPkgVersionString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    return trimmedVersionString;
}

- (BOOL)autoPkgInstalled
{
    NSString *autoPkgPath = @"/usr/local/bin/autopkg";

    if ([[NSFileManager defaultManager] isExecutableFileAtPath:autoPkgPath]) {
        return YES;
    }

    return NO;
}

@end
