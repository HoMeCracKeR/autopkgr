//
//  LGPopularRepositories.h
//  AutoPkgr
//
//  Created by Josh Senick on 7/9/14.
//  Copyright (c) 2014 The Linde Group, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LGAutoPkgRunner.h"

@interface LGPopularRepositories : NSObject <NSApplicationDelegate, NSTableViewDelegate, NSTableViewDataSource> {
    
    IBOutlet NSTableView *popularRepositoriesTableView;
    __weak NSSearchField *_repoSearch;
    
    NSArray *popularRepos;
    NSArray *activeRepos;
    NSArray *searchedRepos;
    LGAutoPkgRunner *pkgRunner;
    BOOL awake;
}

- (void)reload;

@property (weak) IBOutlet NSSearchField *repoSearch;
@end
