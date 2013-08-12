//
//  JuliusSampleAppDelegate.h
//  JuliusSample
//
//  Created by Watanabe Toshinori on 11/01/15.
//  Copyright 2011 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *kPrivateAppDir = @"PrivateDocuments";

#import "MyAudioManager.h"

@class TestViewController;

@interface JuliusSampleAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    
    NSTimer *gainValueTimer;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;

@property (strong, nonatomic) TestViewController *viewController;

@property (nonatomic, strong) IBOutlet UITextView *resultText;
@property (nonatomic, strong) IBOutlet UILabel *notificationLabel;

-(NSString *)applicationLibraryPrivateDocument;

@end

