//
//  JuliusSampleAppDelegate.h
//  JuliusSample
//
//  Created by Watanabe Toshinori on 11/01/15.
//  Copyright 2011 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SSZipArchive.h"

@class JuliusSampleViewController;

static NSString *kPrivateAppDir = @"PrivateDocuments";

@interface JuliusSampleAppDelegate : NSObject <UIApplicationDelegate, SSZipArchiveDelegate> {
    UIWindow *window;
    JuliusSampleViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet JuliusSampleViewController *viewController;

-(NSString *)applicationLibraryPrivateDocument;
@end

