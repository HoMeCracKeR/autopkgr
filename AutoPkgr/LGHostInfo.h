//
//  LGHostInfo.h
//  AutoPkgr
//
//  Created by James Barclay on 6/27/14.
//  Copyright (c) 2014 The Linde Group, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LGHostInfo : NSObject

- (NSString *)getUserName;
- (NSString *)getHostName;
- (NSString *)getUserAtHostName;
- (NSString *)getAutoPkgRecipeOverridesDir;
- (NSString *)getAutoPkgCacheDir;
- (NSString *)getAutoPkgRecipeReposDir;
- (NSString *)getMunkiRepoDir;
- (NSString *)getAutoPkgVersion;
- (BOOL)gitInstalled;
- (BOOL)autoPkgInstalled;

@end
