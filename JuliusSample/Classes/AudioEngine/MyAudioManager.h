//
//  MyAudioManager.h
//  MySpeechAnalysisTool
//
//  Created by OwenWu on 24/07/2013.
//  Copyright (c) 2013 OwenWu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "Julius.h"

#include "aubio.h"

typedef enum {
    LIBAUBIO,
    LIBJULIUS
} AudioLibType;

#define kMaxDuration 5.0 // In sec
#define kFrameNumberInTheFile 1000

@protocol aubioManagerDelegate, juliusManagerDelegate;

@interface MyAudioManager : NSObject <AVAudioRecorderDelegate, AVAudioPlayerDelegate, JuliusDelegate>{
}

@property(nonatomic, assign) AudioLibType aubioORjulius;

@property(nonatomic, assign) BOOL isRealTime;

@property(nonatomic, assign) float sampleRate;//should be set before initializeAudioSession()

@property(nonatomic, weak) id<aubioManagerDelegate> delegateAubio;
@property(nonatomic, weak) id<juliusManagerDelegate> delegateJulius;

+(MyAudioManager *)sharedInstance;

#pragma mark Audio Session Init and Setup
-(void)initializeAudioSession;//should be called after sampleRate is set!

#pragma mark Listen Control for non real-time
-(AVAudioRecorder *)getRecorder;
-(AVAudioPlayer *)getPlayerByPath:(NSURL *)pathURL;//do not use it for now.

#pragma mark Listener Controls for Real-time
-(void)startListening:(id)aListener;
-(void)stopListening;

@end


@protocol juliusManagerDelegate

- (void)juliusCallBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry;

@end


@protocol aubioManagerDelegate

- (void)aubioCallBackResult:(NSArray *)results;

@end