//
//  MyAudioManager.h
//  MySpeechAnalysisTool
//
//  Created by OwenWu on 24/07/2013.
//  Copyright (c) 2013 OwenWu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kMaxDuration 3.0 // Max recording time in sec

#import "MyAubioController.h"
#import "MyJuliusController.h"

@protocol aubioManagerDelegate, juliusManagerDelegate;

@interface MyAudioManager : NSObject <AVAudioPlayerDelegate, juliusControllerDelegate, aubioControllerDelegate> {
}

@property(nonatomic, assign) float sampleRate;//should be set before initializeAudioSession(), default is 16000.0

@property(nonatomic, weak) id<aubioManagerDelegate> delegateAubio;  // aubioCallBackResult() listener
@property(nonatomic, weak) id<juliusManagerDelegate> delegateJulius;// juliusCallBackResult() listener

@property(nonatomic, assign) BOOL isRealTime;// not working for now...

+ (MyAudioManager *)sharedInstance;

#pragma mark Audio Session Init and Setup
- (void)initializeAudioSession;//should be called after sampleRate is set.

#pragma mark Listen Control for non real-time
- (AVAudioRecorder *)getRecorderForJulius;// Julius will return values asynchronously by AVAudioRecorderDelegate method after [recorder stop]
- (AVAudioRecorder *)getRecorderForAubio; // Aubio will return values asynchronously by AVAudioRecorderDelegate method after [recorder stop]

- (AVAudioPlayer *)getPlayerByPath:(NSURL *)pathURL;//do not use it for now.

#pragma mark Listener Controls for real-time - In The Future!
- (void)startListening:(id)aListener;   // not working for now...
- (void)stopListening;                  // not working for now...

@end


@protocol juliusManagerDelegate
- (void)juliusCallBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry;
@end

@protocol aubioManagerDelegate
- (void)aubioCallBackResult:(NSArray *)results;
@end