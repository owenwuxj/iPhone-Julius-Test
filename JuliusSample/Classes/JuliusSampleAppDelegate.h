//
//  JuliusSampleAppDelegate.h
//  JuliusSample
//
//  Created by Watanabe Toshinori on 11/01/15.
//  Copyright 2011 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *kPrivateAppDir = @"PrivateDocuments";

@interface JuliusSampleAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;

-(NSString *)applicationLibraryPrivateDocument;
@end

