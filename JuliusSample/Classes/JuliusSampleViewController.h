//
//  JuliusSampleViewController.h
//  JuliusSample
//
//  Created by Watanabe Toshinori on 11/01/15.
//  Copyright 2011 FLCL.jp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "MBProgressHUD.h"
#import "Julius.h"

@class RIOInterface, DisplayView;

@interface JuliusSampleViewController : UIViewController<AVAudioRecorderDelegate, JuliusDelegate> {
	
	// UI
	UIButton *recordButton;
	UITextView *textView;
	MBProgressHUD *HUD;
    
	AVAudioRecorder *recorder;
	Julius *julius;
    
	NSString *filePath;
	BOOL processing;
    
    // Real-time I/O
    BOOL isListening;
    float currentFrequency;
    
    RIOInterface *rioRef;
    DisplayView *theView;
}

@property (nonatomic, strong) IBOutlet UIButton *recordButton;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) MBProgressHUD *HUD;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) Julius *julius;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, assign) BOOL processing;

@property(nonatomic, assign) float currentFrequency;
@property(nonatomic, assign) float currentFrequencyACF;
@property(nonatomic, assign) float currentFrequencyZCR;
@property(nonatomic, assign) float currentRMS;

- (IBAction)startOrStopRecording:(id)sender;

- (void)frequencyChangedWithRMS:(float)newRMS withACF:(float)newACF andZCR:(float)newZCR withFreq:(float)newFreq;
- (void)updateRMS_ZCR_ACR_Labels;

@end
