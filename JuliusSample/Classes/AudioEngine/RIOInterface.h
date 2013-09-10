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

#include <stdlib.h>

@interface RIOInterface : NSObject {
    void *dataBuffer;
	float *outputBuffer;
    
	size_t bufferCapacity;	// In sample
	size_t index;	// In sample
    
    FFTSetup fftSetup;
	COMPLEX_SPLIT dspSplitComplex;
    int log2n, n, nOver2;

    AUGraph processingGraph;
	AudioUnit ioUnit;
	AudioBufferList* bufferList;
	AudioStreamBasicDescription streamFormat;
    
	float sampleRate;
//	float frequency;
}

@property(nonatomic, assign) float sampleRate;
@property(nonatomic, assign) id juliusListener;

#pragma mark Audio Session/Graph Setup
-(void)initializeAudioSession;

#pragma mark Listener Controls
-(void)startListening:(id)aListener;
-(void)stopListening;

#pragma mark Singleton Methods
+ (RIOInterface *)sharedInstance;

@end
