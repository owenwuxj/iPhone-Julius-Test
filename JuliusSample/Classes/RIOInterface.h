//
//  RIOInterface.h
//  JuliusSample
//
//  Created by OwenWu on 20/05/2013.
//
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "Julius.h"

#include <stdlib.h>

@class JuliusSampleViewController;

@interface RIOInterface : NSObject <JuliusDelegate> {
    UIViewController *selectedViewController;
    JuliusSampleViewController *juliusListener;
    
    void *dataBuffer;
	float *outputBuffer;
	size_t bufferCapacity;	// In samples
	size_t index;	// In samples
    
    FFTSetup fftSetup;
	COMPLEX_SPLIT A;
    int log2n, n, nOver2;

    AUGraph processingGraph;
	AudioUnit ioUnit;
	AudioBufferList* bufferList;
	AudioStreamBasicDescription streamFormat;
    
	float sampleRate;
//	float frequency;
    
    Julius *julius;
}

@property(nonatomic, assign) JuliusSampleViewController *juliusListener;
@property(nonatomic, assign) Julius *julius;
@property(nonatomic, assign) float sampleRate;

#pragma mark Audio Session/Graph Setup
-(void)initializeAudioSession;

-(void)createAUProcessingGraph;
-(size_t)ASBDForSoundMode;
- (void)printASBD:(AudioStreamBasicDescription)asbd;

#pragma mark Listener Controls
-(void)startListening:(JuliusSampleViewController*)aListener;
-(void)stopListening;

#pragma mark Generic Audio Controls
- (void)initializeAndStartProcessingGraph;
- (void)stopProcessingGraph;

#pragma mark Singleton Methods
+ (RIOInterface *)sharedInstance;

@end
