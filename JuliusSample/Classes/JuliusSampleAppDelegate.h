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

@interface JuliusSampleAppDelegate : NSObject <UIApplicationDelegate, juliusManagerDelegate, aubioManagerDelegate> {
    UIWindow *window;
    
    AVAudioRecorder *aRecorder;
    AVAudioRecorder *jRecorder;
    
    NSTimer *gainValueTimer;
}

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) IBOutlet UITextView *resultText;
@property (nonatomic, strong) IBOutlet UILabel *notificationLabel;

-(NSString *)applicationLibraryPrivateDocument;

@end

