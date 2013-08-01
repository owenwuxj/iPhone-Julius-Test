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

@interface MyAudioManager : NSObject <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
{}

@property(nonatomic, assign) float sampleRate;

+(MyAudioManager *)sharedInstance;

#pragma mark Public Methods
-(AVAudioPlayer *)getPlayerByPath:(NSURL *)pathURL;
-(AVAudioRecorder *)getRecorder;
-(NSURL *)fileUrlInDocFolderWithFileName:(NSString *)inputFileName;

#pragma mark Audio Session Init and Setup
-(void)initializeAudioSession;

#pragma mark Listener Controls
-(void)startListening:(id)aListener;
-(void)stopListening;

@end