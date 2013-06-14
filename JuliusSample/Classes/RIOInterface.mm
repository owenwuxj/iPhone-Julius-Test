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

const float MIN_FREQ = 50.0f;// Human actually sounds around 80Hz, male does
const float MAX_FREQ = 2000.0f;// Soprano could actually make 1500Hz

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
    // Set the stream format.
    size_t bytesPerSample = [self ASBDForSoundMode];

	bufferList = (AudioBufferList *)malloc(sizeof(AudioBuffer));
	bufferList->mNumberBuffers = 1;
	bufferList->mBuffers[0].mNumberChannels = 1;
	
	bufferList->mBuffers[0].mDataByteSize = kBufferSize*bytesPerSample;
	bufferList->mBuffers[0].mData = calloc(kBufferSize, bytesPerSample);

    NSError *err = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setPreferredSampleRate:sampleRate error:&err];
    [session setCategory:AVAudioSessionCategoryRecord error:&err];
    [session setActive:YES error:&err];
//    sampleRate = [session preferredSampleRate];
    
    [self realFFTSetup];
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
    
    err = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &streamFormat, sizeof(streamFormat));
    
    err = AudioUnitSetProperty(ioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamFormat, sizeof(streamFormat));
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
-(void)startListening:(id)aListener{
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
    
//    if (!julius) {
//        self.julius = [Julius new];
//        julius.delegate = self;
//    }
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

/* Setup our FFT */
- (void)realFFTSetup {
	UInt32 maxFrames = 2048;
	dataBuffer = (void*)malloc(maxFrames * sizeof(SInt16));
	outputBuffer = (float*)malloc(maxFrames *sizeof(float));
	log2n = log2f(maxFrames);
	n = 1 << log2n;
//    NSLog(@"n is %i",n);
	assert(n == maxFrames);
	nOver2 = maxFrames/2;
	bufferCapacity = maxFrames;
	index = 0;
	A.realp = (float *)malloc(nOver2 * sizeof(float));
	A.imagp = (float *)malloc(nOver2 * sizeof(float));
	fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
}

#pragma mark -
#pragma mark Audio Rendering
OSStatus RenderFFTCallback (void					*inRefCon,
                            AudioUnitRenderActionFlags 	*ioActionFlags,
                            const AudioTimeStamp		*inTimeStamp,
                            UInt32 						inBusNumber,
                            UInt32 						inNumberFrames,
                            AudioBufferList				*ioData)
{
	RIOInterface* THIS = (RIOInterface *)inRefCon;
	COMPLEX_SPLIT A = THIS->A;
	FFTSetup fftSetup = THIS->fftSetup;

    void *dataBuffer = THIS->dataBuffer;
	float *outputBuffer = THIS->outputBuffer;

    int bufferCapacity = THIS->bufferCapacity;
	SInt16 index = THIS->index;

	AudioUnit rioUnit = THIS->ioUnit;
	OSStatus renderErr;
	UInt32 bus1 = 1;

	uint32_t log2n = THIS->log2n;
	uint32_t n = THIS->n;
	uint32_t nOver2 = THIS->nOver2;
	uint32_t stride = 1;

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
        
        // Create a Hanning window
        float *hann = (float*)malloc(sizeof(float)*bufferCapacity);
        vDSP_hann_window(hann, bufferCapacity, vDSP_HANN_NORM);

        /******RMS or ZCR or ACF*****/
        //RMS
        float sum = 0.0;
//        float sum4i,sum4ACFinal = 0.0;
        
        for (int i=0; i<n; i++) {
            sum = sum + outputBuffer[i]*outputBuffer[i]*hann[i];
        }
        float rmsOfThisFrame = sqrtf(sum/n);
    
		/*************** FFT ***************/
        // Only a rectangle windowing/framing, no overlapping and pick the highest peak??!
		// We want to deal with only floating point values here.
        
		/**
		 Look at the real signal as an interleaved complex vector by casting it.
		 Then call the transformation function vDSP_ctoz to get a split complex
		 vector, which for a real signal, divides into an even-odd configuration.
		 */
		vDSP_ctoz((COMPLEX*)outputBuffer, 2, &A, 1, nOver2);
		
		// Carry out a Forward FFT transform.
		vDSP_fft_zrip(fftSetup, &A, stride, log2n, FFT_FORWARD);
		
		// The output signal is now in a split real form. Use the vDSP_ztoc to get
		// a split real vector.
		vDSP_ztoc(&A, 1, (COMPLEX *)outputBuffer, 2, nOver2);
		
        
        // Apply Cutoff
        int bin = 0;
        float max = outputBuffer[0];
        
        int startBin = (int) (MIN_FREQ * n * 2 / THIS->sampleRate) - 1;
        if (startBin < 1)
            startBin = 1;  // we've already looked at bin 0
        
        int endBin = (int) (MAX_FREQ * n * 2 / THIS->sampleRate) + 1;
        if (endBin > n)
            endBin = n;
        
        //        NSLog(@"Start:%d / End:%d",startBin, endBin);
        
        for (int i = startBin; i < endBin; i++)
        {
            if (outputBuffer[i] > max)
            {
                max = outputBuffer[i];
                bin = i;
            }
        }
        
        // Check Again: Freq
        if (bin*THIS->sampleRate/bufferCapacity/2 < MIN_FREQ) {
            bin = 0;
        }
        
        // Check Again: Noise Amplitude
        if (max < 20) bin = 0;

		memset(outputBuffer, 0, n*sizeof(SInt16));

//        [THIS->julius recognizeRawFileAtPath:(NSString *)dataBuffer];
        if (THIS->juliusListener && [THIS->juliusListener respondsToSelector:@selector(frequencyChangedWithRMS:withACF:andZCR:withFreq:)]) {
            [THIS->juliusListener frequencyChangedWithRMS:rmsOfThisFrame withACF:nil andZCR:nil withFreq:bin*(THIS->sampleRate/bufferCapacity/2)];
        }
    }

    return noErr;
}

#pragma mark -
#pragma mark Julius delegate

- (void)callBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry{
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
