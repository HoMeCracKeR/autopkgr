//
//  LGDefaults.m
//  AutoPkgr
//
//  Created by Eldon on 8/5/14.
//
//  Copyright 2014 The Linde Group, Inc.
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

#import "LGDefaults.h"
#import "LGConstants.h"

@interface LGDefaults ()
// Make these readwrite here so we can use these with methods
@property (copy, nonatomic, readwrite) NSString *autoPkgRecipeRepoDir;
@property (copy, nonatomic, readwrite) NSArray *autoPkgRecipeSearchDirs;
@property (copy, nonatomic, readwrite) NSDictionary *autoPkgRecipeRepos;
@end

@implementation LGDefaults {
    LGDefaults *_autoPkgDefaults;
}

+ (LGDefaults *)autoPkgDefaults
{
    static dispatch_once_t onceToken;
    static LGDefaults *shared;
    dispatch_once(&onceToken, ^{
        shared = [[LGDefaults alloc] initForAutoPkg];
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _autoPkgDefaults = [[[self class] alloc] initForAutoPkg];
    }
    return self;
}

- (instancetype)initForAutoPkg
{
    return [super initWithSuiteName:@"com.github.autopkg"];
}

- (instancetype)initForMunki
{
    return [super initWithSuiteName:@"ManagedInstalls"];
}

- (BOOL)synchronize
{
    if ([super synchronize] && [self->_autoPkgDefaults synchronize]) {
        return YES;
    }
    return NO;
}

#pragma mark - EMail
//
- (NSString *)SMTPServer
{
    return [self objectForKey:kSMTPServer];
}
- (void)setSMTPServer:(NSString *)SMTPServer
{
    [self setObject:SMTPServer forKey:kSMTPServer];
}
//
- (NSInteger)SMTPPort
{
    return [self integerForKey:kSMTPPort];
}
- (void)setSMTPPort:(NSInteger)SMTPPort
{
    [self setInteger:SMTPPort forKey:kSMTPPort];
}
//
- (NSString *)SMTPUsername
{
    return [self objectForKey:kSMTPUsername];
}
- (void)setSMTPUsername:(NSString *)SMTPUsername
{
    [self setObject:SMTPUsername forKey:kSMTPUsername];
}
//
- (NSString *)SMTPFrom
{
    return [self objectForKey:kSMTPFrom];
}
- (void)setSMTPFrom:(NSString *)SMTPFrom
{
    [self setObject:SMTPFrom forKey:kSMTPFrom];
}
//
- (NSArray *)SMTPTo
{
    return [self objectForKey:kSMTPUsername];
}
//
- (void)setSMTPTo:(NSArray *)SMTPTo
{
    [self setObject:SMTPTo forKey:kSMTPTo];
}

#pragma mark - BOOL
- (BOOL)SMTPTLSEnabled
{
    return [self boolForKey:kSMTPTLSEnabled];
}
- (void)setSMTPTLSEnabled:(BOOL)SMTPTLSEnabled
{
    [self setBool:SMTPTLSEnabled forKey:kSMTPTLSEnabled];
}
//
- (BOOL)SMTPAuthenticationEnabled
{
    return [self boolForKey:kSMTPTLSEnabled];
}
- (void)setSMTPAuthenticationEnabled:(BOOL)SMTPAuthenticationEnabled
{
    [self setBool:SMTPAuthenticationEnabled forKey:kSMTPAuthenticationEnabled];
}
//
- (BOOL)warnBeforeQuittingEnabled
{
    return [self boolForKey:kWarnBeforeQuittingEnabled];
}
- (void)setWarnBeforeQuittingEnabled:(BOOL)WarnBeforeQuittingEnabled
{
    [self setBool:WarnBeforeQuittingEnabled forKey:kWarnBeforeQuittingEnabled];
}
//
- (BOOL)hasCompletedInitialSetup
{
    return [self boolForKey:kHasCompletedInitialSetup];
}
- (void)setHasCompletedInitialSetup:(BOOL)HasCompletedInitialSetup
{
    [self setBool:HasCompletedInitialSetup forKey:kHasCompletedInitialSetup];
}
//
- (BOOL)sendEmailNotificationsWhenNewVersionsAreFoundEnabled
{
    return [self boolForKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled];
}
- (void)setSendEmailNotificationsWhenNewVersionsAreFoundEnabled:(BOOL)SendEmailNotificationsWhenNewVersionsAreFoundEnabled
{
    [self setBool:SendEmailNotificationsWhenNewVersionsAreFoundEnabled forKey:kSendEmailNotificationsWhenNewVersionsAreFoundEnabled];
}
//
- (BOOL)checkForNewVersionsOfAppsAutomaticallyEnabled
{
    return [self boolForKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled];
}
- (void)setCheckForNewVersionsOfAppsAutomaticallyEnabled:(BOOL)CheckForNewVersionsOfAppsAutomaticallyEnabled
{
    [self setBool:CheckForNewVersionsOfAppsAutomaticallyEnabled forKey:kCheckForNewVersionsOfAppsAutomaticallyEnabled];
}
//

#pragma mark - AutoPkg Defaults
- (NSInteger)autoPkgRunInterval
{
    return [self integerForKey:kAutoPkgRunInterval];
}
- (void)setAutoPkgRunInterval:(NSInteger)autoPkgRunInterval
{
    [self setInteger:autoPkgRunInterval forKey:kAutoPkgRunInterval];
}
//
- (NSString *)autoPkgCacheDir
{
    return [_autoPkgDefaults objectForKey:@"CACHE_DIR"];
}
- (void)setAutoPkgCacheDir:(NSString *)autoPkgCacheDir
{
    [_autoPkgDefaults setObject:autoPkgCacheDir forKey:@"CACHE_DIR"];
}
//
- (NSString *)autoPkgRecipeRepoDir
{
    return [_autoPkgDefaults objectForKey:@"RECIPE_REPO_DIR"];
}
- (void)setAutoPkgRecipeRepoDir:(NSString *)autoPkgRecipeRepoDir
{
    [_autoPkgDefaults setObject:autoPkgRecipeRepoDir forKey:@"RECIPE_REPO_DIR"];
}
//
- (NSArray *)autoPkgRecipeSearchDirs
{
    return [_autoPkgDefaults objectForKey:@"RECIPE_SEARCH_DIRS"];
}

- (void)setAutoPkgRecipeSearchDirs:(NSArray *)autoPkgRecipeSearchDirs
{
    [_autoPkgDefaults setObject:autoPkgRecipeSearchDirs forKey:@"RECIPE_SEARCH_DIRS"];
}
//
- (NSDictionary *)autoPkgRecipeRepos
{
    return [_autoPkgDefaults objectForKey:@"RECIPE_REPOS"];
}
- (void)setAutoPkgRecipeRepos:(NSDictionary *)autoPkgRecipeRepos
{
    [_autoPkgDefaults setObject:autoPkgRecipeRepos forKey:@"RECIPE_REPOS"];
}
//
- (NSString *)munkiRepo
{
    return [_autoPkgDefaults objectForKey:@"MUNKI_REPO"];
}
- (void)setMunkiRepo:(NSString *)munkiRepo
{
    [_autoPkgDefaults setObject:munkiRepo forKey:@"MUNKI_REPO"];
}
//

#pragma Class Methods
+ (BOOL)fixRelativePathsInAutoPkgDefaults
{
    LGDefaults *defaults = [LGDefaults new];

    BOOL neededFixing = NO;
    if ([[defaults.autoPkgRecipeRepoDir pathComponents].firstObject isEqualToString:@"~"]) {
        NSLog(@"%@", [defaults.autoPkgRecipeRepoDir stringByExpandingTildeInPath]);
        defaults.autoPkgRecipeRepoDir = defaults.autoPkgRecipeRepoDir.stringByExpandingTildeInPath;
        neededFixing = YES;
    }

    NSMutableArray *newRecipeSearchDirs = [NSMutableArray new];
    for (NSString *dir in defaults.autoPkgRecipeSearchDirs) {
        if ([[dir pathComponents].firstObject isEqualToString:@"~"]) {
            [newRecipeSearchDirs addObject:[dir stringByExpandingTildeInPath]];
            neededFixing = YES;
        } else if ([dir length] > 1 && [[dir substringToIndex:2] isEqualToString:@"/~"]) {
            [newRecipeSearchDirs addObject:[[dir substringFromIndex:1] stringByExpandingTildeInPath]];
            neededFixing = YES;
        } else {
            [newRecipeSearchDirs addObject:dir];
        }
    }
    defaults.autoPkgRecipeSearchDirs = newRecipeSearchDirs;

    NSMutableDictionary *newRecipeRepos = [NSMutableDictionary new];
    for (NSString *key in defaults.autoPkgRecipeRepos.allKeys) {
        if ([[key pathComponents].firstObject isEqualToString:@"~"]) {
            [newRecipeRepos setObject:defaults.autoPkgRecipeRepos[key] forKey:[key stringByExpandingTildeInPath]];
            neededFixing = YES;
        } else if ([key length] > 1 && [[key substringToIndex:2] isEqualToString:@"/~"]) {
            [newRecipeRepos setObject:defaults.autoPkgRecipeRepos[key] forKey:[[key substringFromIndex:1] stringByExpandingTildeInPath]];
            neededFixing = YES;
        } else {
            [newRecipeRepos setObject:defaults.autoPkgRecipeRepos[key] forKey:key];
        }
    }
    defaults.autoPkgRecipeRepos = newRecipeRepos;
    [defaults synchronize];
    return neededFixing;
}

@end
