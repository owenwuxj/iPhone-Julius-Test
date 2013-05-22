//
//  RIOInterface.m
//  JuliusSample
//
//  Created by OwenWu on 20/05/2013.
//
//

#import "RIOInterface.h"

#import "CAStreamBasicDescription.h"
#import "CAXException.h"

#import "JuliusSampleViewController.h"
#import "Julius.h"

#define kBufferSize 1024*2

@implementation RIOInterface

@synthesize juliusListener, sampleRate, julius;

void ConvertInt16ToFloat(RIOInterface* THIS, void *buf, float *outputBuf, size_t capacity);

- (void)dealloc {
	if (processingGraph) {
		AUGraphStop(processingGraph);
	}
	
	// Clean up the audio session
	AVAudioSession *session = [AVAudioSession sharedInstance];
	[session setActive:NO error:nil];
	
	[super dealloc];
}

#pragma mark Audio Session/Graph Setup

-(void)initializeAudioSession{
    NSError *err = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setPreferredSampleRate:sampleRate error:&err];
    [session setCategory:AVAudioSessionCategoryRecord error:&err];
    [session setActive:YES error:&err];
//    sampleRate = [session preferredSampleRate];
    
	UInt32 maxFrames = 2048;
    dataBuffer = (void*)malloc(maxFrames * sizeof(SInt16));
	outputBuffer = (float*)malloc(maxFrames *sizeof(float));
//	log2n = log2f(maxFrames);
//	n = 1 << log2n;
//  NSLog(@"n is %i",n);
//	assert(n == maxFrames);
//	nOver2 = maxFrames/2;
	bufferCapacity = maxFrames;
	index = 0;
}

-(void)createAUProcessingGraph{
    AudioComponentDescription ioUnitDescription;
    ioUnitDescription.componentType = kAudioUnitType_Output;
    ioUnitDescription.componentSubType = kAudioUnitSubType_RemoteIO;
    ioUnitDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioUnitDescription.componentFlags = 0;
    ioUnitDescription.componentFlagsMask = 0;

    OSStatus err;
    NewAUGraph(&processingGraph);
    
    AUNode ioNode;
    AUGraphAddNode(processingGraph, &ioUnitDescription, &ioNode);
    
    AUGraphOpen(processingGraph);// indirectly performs audio unit instantiation
    
    AUGraphNodeInfo(processingGraph, ioNode, nil, &ioUnit);
    
    // Initialize below.
	AURenderCallbackStruct callbackStruct = {0};
	UInt32 enableInput = 1;
	UInt32 enableOutput = 0;
    callbackStruct.inputProc = RenderFFTCallback;
    callbackStruct.inputProcRefCon = self;
    
    err = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &enableInput, sizeof(enableInput));
    
	err = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output,0, &enableOutput, sizeof(enableOutput));
	
	err = AudioUnitSetProperty(ioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Input,0, &callbackStruct, sizeof(callbackStruct));
    
    // Set the stream format.
    size_t bytesPerSample = [self ASBDForSoundMode];
    
    err = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &streamFormat, sizeof(streamFormat));
    
    err = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(streamFormat));
    
	// Allocate AudioBuffers for use when listening.
	// TODO: Move into initialization...should only be required once.
    // ????
	bufferList = (AudioBufferList *)malloc(sizeof(AudioBuffer));
	bufferList->mNumberBuffers = 1;
	bufferList->mBuffers[0].mNumberChannels = 1;
	
	bufferList->mBuffers[0].mDataByteSize = kBufferSize*bytesPerSample;
	bufferList->mBuffers[0].mData = calloc(kBufferSize, bytesPerSample);
}

// Set the AudioStreamBasicDescription for listening to audio data. Set the
// stream member var here as well.
- (size_t)ASBDForSoundMode {
	AudioStreamBasicDescription asbd = {0};
	size_t bytesPerSample;
	bytesPerSample = sizeof(SInt16);
	asbd.mFormatID = kAudioFormatLinearPCM;
	asbd.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
	asbd.mBitsPerChannel = 8 * bytesPerSample;
	asbd.mFramesPerPacket = 1;
	asbd.mChannelsPerFrame = 1;
	asbd.mBytesPerPacket = bytesPerSample * asbd.mFramesPerPacket;
	asbd.mBytesPerFrame = bytesPerSample * asbd.mChannelsPerFrame;
	asbd.mSampleRate = sampleRate;
	
	streamFormat = asbd;
	[self printASBD:streamFormat];
	
	return bytesPerSample;
}

#pragma mark -
#pragma mark Utility
- (void)printASBD:(AudioStreamBasicDescription)asbd {
	
    char formatIDString[5];
    UInt32 formatID = CFSwapInt32HostToBig (asbd.mFormatID);
    bcopy (&formatID, formatIDString, 4);
    formatIDString[4] = '\0';
	
    NSLog (@"  Sample Rate:         %10.0f",  asbd.mSampleRate);
    NSLog (@"  Format ID:           %10s",    formatIDString);
    NSLog (@"  Format Flags:        %10lX",    asbd.mFormatFlags);
    NSLog (@"  Bytes per Packet:    %10ld",    asbd.mBytesPerPacket);
    NSLog (@"  Frames per Packet:   %10ld",    asbd.mFramesPerPacket);
    NSLog (@"  Bytes per Frame:     %10ld",    asbd.mBytesPerFrame);
    NSLog (@"  Channels per Frame:  %10ld",    asbd.mChannelsPerFrame);
    NSLog (@"  Bits per Channel:    %10ld",    asbd.mBitsPerChannel);
}

#pragma mark Listener Controls
-(void)startListening:(JuliusSampleViewController*)aListener{
	self.juliusListener = aListener;
	[self createAUProcessingGraph];
	[self initializeAndStartProcessingGraph];
}

-(void)stopListening{
    [self stopProcessingGraph];
}

#pragma mark Generic Audio Controls
- (void)initializeAndStartProcessingGraph{
    OSStatus result = AUGraphInitialize(processingGraph);
    if (result >= 0) {
        AUGraphStart(processingGraph);
    } else {
		XThrow(result, "error initializing processing graph");
    }
    
    if (!julius) {
        self.julius = [Julius new];
        julius.delegate = self;
    }
}

- (void)stopProcessingGraph{
    AUGraphStop(processingGraph);
}

void ConvertInt16ToFloat(RIOInterface* THIS, void *buf, float *outputBuf, size_t capacity) {
	AudioConverterRef converter;
	OSStatus err;
	
	size_t bytesPerSample = sizeof(float);
	AudioStreamBasicDescription outFormat = {0};
	outFormat.mFormatID = kAudioFormatLinearPCM;
	outFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
	outFormat.mBitsPerChannel = 8 * bytesPerSample;
	outFormat.mFramesPerPacket = 1;
	outFormat.mChannelsPerFrame = 1;
	outFormat.mBytesPerPacket = bytesPerSample * outFormat.mFramesPerPacket;
	outFormat.mBytesPerFrame = bytesPerSample * outFormat.mChannelsPerFrame;
	outFormat.mSampleRate = THIS->sampleRate;
	
	const AudioStreamBasicDescription inFormat = THIS->streamFormat;
	
	UInt32 inSize = capacity*sizeof(SInt16);
	UInt32 outSize = capacity*sizeof(float);
	err = AudioConverterNew(&inFormat, &outFormat, &converter);
	err = AudioConverterConvertBuffer(converter, inSize, buf, &outSize, outputBuf);
}

#pragma mark -
#pragma mark Audio Rendering
OSStatus RenderFFTCallback (void					*inRefCon,
                            AudioUnitRenderActionFlags 	*ioActionFlags,
                            const AudioTimeStamp			*inTimeStamp,
                            UInt32 						inBusNumber,
                            UInt32 						inNumberFrames,
                            AudioBufferList				*ioData)
{
	RIOInterface* THIS = (RIOInterface *)inRefCon;
    
    void *dataBuffer = THIS->dataBuffer;
	float *outputBuffer = THIS->outputBuffer;

    int bufferCapacity = THIS->bufferCapacity;
	SInt16 index = THIS->index;

	AudioUnit rioUnit = THIS->ioUnit;
	OSStatus renderErr;
	UInt32 bus1 = 1;

	renderErr = AudioUnitRender(rioUnit, ioActionFlags, inTimeStamp, bus1, inNumberFrames, THIS->bufferList);
	if (renderErr < 0) {
		return renderErr;
	}

    // Fill the buffer with our sampled data. If we fill our buffer, run the
	// fft.
	int read = bufferCapacity - index;
    if (read > inNumberFrames) {
		memcpy((SInt16 *)dataBuffer + index, THIS->bufferList->mBuffers[0].mData, inNumberFrames*sizeof(SInt16));
		THIS->index += inNumberFrames;
	} else {
		// If we enter this conditional, our buffer will be filled and we should
		// perform the FFT.
		memcpy((SInt16 *)dataBuffer + index, THIS->bufferList->mBuffers[0].mData, read*sizeof(SInt16));
		
		// Reset the index.
		THIS->index = 0;
        
		// We want to deal with only floating point values here.
		ConvertInt16ToFloat(THIS, dataBuffer, outputBuffer, bufferCapacity);
        
//        NSLog(@"%f",outputBuffer[10]);
        for (int i = 0; i < kBufferSize; i++) {
//            NSLog(@"%f",outputBuffer[i]);
        }
    
        [THIS->julius recognizeRawFileAtPath:(NSString *)dataBuffer];
    }

    return noErr;
}

#pragma mark -
#pragma mark Julius delegate

- (void)callBackResult:(NSArray *)results {
//	[HUD hide:YES];
    
	// Show results.
//	textView.text = [results componentsJoinedByString:@""];
}

// *************** Singleton *********************

static RIOInterface *sharedInstance = nil;

#pragma mark -
#pragma mark Singleton Methods
+ (RIOInterface *)sharedInstance
{
	if (sharedInstance == nil) {
		sharedInstance = [[RIOInterface alloc] init];
	}
	
	return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (id)retain {
    return self;
}

- (unsigned)retainCount {
    return UINT_MAX;  // denotes an object that cannot be released
}

- (oneway void)release {
    //do nothing
}

- (id)autorelease {
    return self;
}

@end
