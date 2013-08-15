//
//  SuperAudioManager.h
//  JuliusSample
//
//  Created by Matthew Magee on 08/08/2013.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#include "aubio.h"
#import "Julius.h"

@interface SuperAudioManager : NSObject <AVAudioRecorderDelegate, JuliusDelegate>

@property (nonatomic) AVAudioRecorder *genericAudioRecorder;

+ (SuperAudioManager *)sharedInstance;

- (void)micRecordingStart:(AVAudioRecorder*)pAudioRecorder;

- (void)micRecordingEnd:(AVAudioRecorder*)pAudioRecorder;

- (NSArray*)extractPitchFloatArrayFromFile:(NSURL*)pFilename;

- (NSArray*)extractWordsFromFile:(NSURL*)pFilename;

@end
