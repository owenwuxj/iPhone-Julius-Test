//
//  MyAudioManager.m
//  MySpeechAnalysisTool
//
//  Created by OwenWu on 24/07/2013.
//  Copyright (c) 2013 OwenWu. All rights reserved.
//

#import "MyAudioManager.h"

#include "utils.h"

#define kBufferSize 512
#define kBufferSizeInFloat 512.0
#define kMinTimeout 2.0    // In sec

#define kSamplingRate 16000

unsigned int pos = 0; /*frames%dspblocksize*/
aubio_source_t *that_source = NULL;

/* pitch objects */
aubio_pitch_t *pitchObject;
fvec_t *pitch;

float floatFreq;

@interface MyAudioManager ()
{
    void *dataBuffer;
	float *outputBuffer;
	size_t bufferCapacity;	// In samples
	size_t index;	// In samples

    AUGraph processingGraph;
	AudioUnit ioUnit;
	AudioBufferList* bufferList;
	AudioStreamBasicDescription streamFormat;

    AVAudioRecorder *recorder;
    AVAudioPlayer *player;

	Julius *julius;
    float *pitchArray;
}

@property(nonatomic, assign) id theListener;

#pragma mark Audio Graph Setup and Create
-(void)createAUProcessingGraph;
-(size_t)ASBDForSoundMode;
-(void)printASBD:(AudioStreamBasicDescription)asbd;

#pragma mark Generic Audio Controls
- (void)initializeAndStartProcessingGraph;
- (void)stopProcessingGraph;
- (NSURL *)fileUrlInDocFolderWithFileName:(NSString *)inputFileName;

void ConvertInt16ToFloat(MyAudioManager* THIS, void *buf, float *outputBuf, size_t capacity);

@end

@implementation MyAudioManager

@synthesize theListener;
@synthesize aubioORjulius, isRealTime;
@synthesize delegateAubio, delegateJulius;

unsigned int posInFrame = 0; /*frames%dspblocksize*/
int framesRIO = 0;

#pragma mark -
#pragma mark Aubio Callback Methods

static int aubio_process(smpl_t **input, smpl_t **output, int nframes) {
    unsigned int j;       /*frames*/
    for (j=0;j<(unsigned)nframes;j++) {
        if(usejack) {
            /* write input to datanew */
            fvec_write_sample(ibuf, input[0][j], pos);
            /* put synthnew in output */
            output[0][j] = fvec_read_sample(obuf, pos);
        }
        /*time for fft*/
        if (pos == overlap_size-1) {
            /* block loop */
            aubio_pitch_do (pitchObject, ibuf, pitch);
            //            aubio_onset_do(onsetObject, ibuf, onset);
            
            if (fvec_read_sample(pitch, 0)) {
                for (pos = 0; pos < overlap_size; pos++){
                    // TODO, play sine at this freq
                }
            } else {
                fvec_zeros (obuf);
            }
            
            //            if (fvec_read_sample(onset, 0)) {
            //                fvec_copy(woodblock, obuf);
            //            } else {
            //                fvec_zeros(obuf);
            //            }
            /* end of block loop */
            
            pos = -1; /* so it will be zero next j loop */
        }
        pos++;
    }
    return 1;
}

static void process_print (void) {
    if (!verbose && usejack) return;
    smpl_t pitch_found = fvec_read_sample(pitch, 0);
    outmsg("Time:%f Freq:%f\n",(frames)*overlap_size/(float)samplerate, pitch_found);
    
//    smpl_t onset_found = fvec_read_sample (onset, 0);
//    if (onset_found) {
//        outmsg ("Onset:%f\n", aubio_onset_get_last_s (onsetObject) );
//    }
}

#pragma mark Audio Session/Graph Setup

-(void)initializeAudioSession{
    NSError *err = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setPreferredSampleRate:_sampleRate error:&err];
    [session setCategory:AVAudioSessionCategoryRecord error:&err];

    if(session == nil) {
        NSLog(@"Error creating session: %@", [err description]);
    }
    else {
        [session setActive:YES error:nil];
    }
    
//    sampleRate = [session preferredSampleRate];
    
    if (isRealTime) {
        [self realFFTSetup];
    }
}

#pragma mark Listener Controls

-(void)startListening:(id)aListener{
	self.theListener = aListener;
	[self createAUProcessingGraph];
	[self initializeAndStartProcessingGraph];
}

-(void)stopListening{
    [self stopProcessingGraph];
}


/* Setup our FFT */
- (void)realFFTSetup {
	UInt32 maxFrames = kBufferSize;
	dataBuffer = (void*)malloc(maxFrames * sizeof(SInt16));
	outputBuffer = (float*)malloc(maxFrames *sizeof(float));
    //	log2n = log2f(maxFrames);
    //	n = 1 << log2n;
    //    NSLog(@"n is %i",n);
    //	assert(n == maxFrames);
    //	nOver2 = maxFrames/2;
	bufferCapacity = maxFrames;
	index = 0;
    //	A.realp = (float *)malloc(nOver2 * sizeof(float));
    //	A.imagp = (float *)malloc(nOver2 * sizeof(float));
    //	fftSetup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    
    framesRIO = 0;
    //    self.timer = [[NSTimer alloc] init];
}

void ConvertInt16ToFloat(MyAudioManager* THIS, void *buf, float *outputBuf, size_t capacity) {
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
	outFormat.mSampleRate = THIS.sampleRate;
	
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
                            const AudioTimeStamp		*inTimeStamp,
                            UInt32 						inBusNumber,
                            UInt32 						inNumberFrames,
                            AudioBufferList				*ioData)
{
	MyAudioManager* THIS = (__bridge MyAudioManager*)inRefCon;
    
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
        
        NSLog(@"SInt16 data[0]:%d", ((SInt16 *)dataBuffer)[0]);
        
		// We want to deal with only floating point values here.
		ConvertInt16ToFloat(THIS, dataBuffer, outputBuffer, bufferCapacity);
        
//        for (int idx = 0; idx<bufferCapacity; idx++) {
            NSLog(@"float data[0]:%f", outputBuffer[0]);
//        }

////        NSDate *startDate = [NSDate date];
        int argc = 1;
        char *argv =  "aubiopitch -i";
        examples_common_init(argc,&argv);
//
        pitchObject = new_aubio_pitch ("yin", buffer_size, overlap_size, THIS.sampleRate);
        pitch = new_fvec (1);
        
        ibuf->data = outputBuffer;            //
        ibuf->length = kBufferSizeInFloat/2;//

//        examples_common_process(aubio_process,process_print);
//        aubio_source_do(that_source, ibuf, &read);
        unsigned int j;       /*frames*/
        for (j=0;j<(unsigned)overlap_size;j++) {
            /*time for fft*/
            if (posInFrame == overlap_size-1) {
                /* block loop */
                aubio_pitch_do (pitchObject, ibuf, pitch);
                
                if (fvec_read_sample(pitch, 0)) {
                    for (posInFrame = 0; posInFrame < overlap_size; posInFrame++){
                        // TODO, play sine at this freq
                    }
                } else {
                    fvec_zeros (obuf);
                }
                /* end of block loop */
                
                posInFrame = -1; /* so it will be zero next j loop */
            }
            posInFrame++;
        }
        
        if (!verbose && usejack) return noErr;
        smpl_t pitch_found = fvec_read_sample(pitch, 0);
        outmsg("Time:%f Freq:%f\n",(framesRIO)*kBufferSize/(float)THIS.sampleRate, pitch_found);
        
        framesRIO++;
        
        del_aubio_pitch (pitchObject);
        del_fvec (pitch);
        
        // Do some work
//        NSDate *endDate = [NSDate date];
//        NSLog(@"Total time was: %lf milliseconds", [endDate timeIntervalSinceDate:startDate]);

//        examples_common_del();
//        debug("End of program.\n");
//        fflush(stderr);

//		memset(outputBuffer, 0, n*sizeof(SInt16));

//        [THIS->julius recognizeRawFileAtPath:(NSString *)dataBuffer];
//        [THIS->juliusListener frequencyChangedWithRMS:rmsOfThisFrame withACF:nil andZCR:nil withFreq:bin*(THIS->sampleRate/bufferCapacity/2)];
    }
    
    return noErr;
}

#pragma mark Generic Audio Controls
- (void)initializeAndStartProcessingGraph{
    OSStatus result = AUGraphInitialize(processingGraph);
    if (result >= 0) {
        AUGraphStart(processingGraph);
    } else {
//		XThrow(result, "error initializing processing graph");
    }
}

- (void)stopProcessingGraph{
    AUGraphStop(processingGraph);
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
    callbackStruct.inputProcRefCon = (__bridge void *)(self);//OWEN
    
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
	asbd.mSampleRate = _sampleRate;
	
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

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)aPlayer
{
	[aPlayer stop];
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}


- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}


- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}


#pragma mark -
#pragma mark AVAudioRecorderDelegate

- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)aRecorder
{
	[aRecorder stop];
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}

-(void)initializeAubioWithRecorder:(AVAudioRecorder *)theRecorder {
    NSString *path = [NSString stringWithFormat:@"%@",[theRecorder.url relativePath]];
    char *temp = (char *)[path UTF8String];
    
    NSLog(@"filePath is %@",path);
    
    //    examples_common_init(argc,&temp);
    debug ("Opening files ...\n");
    that_source = new_aubio_source ((char_t *)temp, 0, overlap_size);
    if (that_source == NULL) {
        outmsg ("Could not open input file %s.\n", temp);
        exit (1);
    }
    samplerate = aubio_source_get_samplerate(that_source);
    
    woodblock = new_fvec (overlap_size);
    ibuf = new_fvec (overlap_size);
    obuf = new_fvec (overlap_size);
    
    pitchObject = new_aubio_pitch ("yin", buffer_size, overlap_size, samplerate);
    //    if (threshold != 0.) {
    //        aubio_pitch_set_silence(pitchObject, -60);
    //        aubio_pitch_set_unit(pitchObject, "freq");
    //    }
    pitch = new_fvec (1);
    
    //    examples_common_process(aubio_process,process_print);
    uint_t read = 0;
    debug ("Processing 1 ...\n");
    frames = 0;
    do {
        aubio_source_do (that_source, ibuf, &read);
        aubio_process (&ibuf->data, &obuf->data, overlap_size);
        process_print ();
        frames++;
    } while (read == overlap_size);
    del_aubio_pitch (pitchObject);
    del_fvec (pitch);
    
    debug ("Processed %d frames of %d samples.\n", frames, buffer_size);
    
//    for (int idx = 0; idx < frames; idx++) {
//        [self.pitchArray addObject:[NSNumber numberWithFloat:pitchAry[idx]]];
//    }
    
#ifdef DEBUG
    //    DLog(@"pitchArray cnt: %d", [self.pitchArray count]);
#endif
    
    //    del_aubio_pitch (pitchObject);
    //    del_fvec (pitch);
    //    del_aubio_onset(onsetObject);
    //    del_fvec(onset);
    
    if (self.delegateAubio) {
        [self.delegateAubio aubioCallBackResult:nil];
    }
    
    examples_common_del();
    debug("End of program.\n");
    fflush(stderr);
}

-(void)initializeJuliusWithRecorder:(AVAudioRecorder *)theRecorder{
	if (!julius) {
		julius = [Julius new];
		julius.delegate = self;
	}
    else {// Owen 20130607: Init Julius every time starting recognition
        julius = nil;
        julius = [Julius new];
        julius.delegate = self;
    }
    
    NSLog(@"filePath is %@",[theRecorder.url relativePath]);
	[julius recognizeRawFileAtPath:[theRecorder.url relativePath]];
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)theRecorder successfully:(BOOL)flag
{
    if (aubioORjulius == LIBAUBIO) {
        [self initializeAubioWithRecorder:theRecorder];
    }
    else if (aubioORjulius == LIBJULIUS) {
        [self performSelectorInBackground:@selector(initializeJuliusWithRecorder:) withObject:theRecorder];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder
{
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}

#pragma mark -
#pragma mark Julius delegate

- (void)callBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry{
    NSLog(@"Show Results: %@ /n has %d bounds",[results componentsJoinedByString:@""], [boundsAry count]);    
    if (self.delegateJulius) {
        [self.delegateJulius juliusCallBackResult:results withBounds:boundsAry];
    }
}

// *************** Singleton *********************

#pragma mark -
#pragma mark Singleton Methods

+(MyAudioManager *)sharedInstance{
    static MyAudioManager *_instance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_instance) {
            _instance = [[MyAudioManager alloc] init];
        }
    });
    return _instance;
}

#pragma mark -
#pragma mark Public Methods
- (AVAudioPlayer *)getPlayerByPath:(NSURL *)pathURL{
    NSError *playerError;
    
    // Setup audio session
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:pathURL error:&playerError];
    
    if (playerError) {
        NSLog(@"%@",playerError);
    }
    
    player.meteringEnabled = YES;
    //    player.delegate = self;
    
    return player;
}

-(NSURL *)fileUrlInDocFolderWithFileName:(NSString *)inputFileName{
    NSArray *pathComponents = [NSArray arrayWithObjects:
                               [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                               inputFileName,
                               nil];
    return [NSURL fileURLWithPathComponents:pathComponents];
}

- (AVAudioRecorder *)getRecorder
{
    // Create file path.
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyyMMddHHmmss"];
	NSString *fileName = [NSString stringWithFormat:@"%@.wav", [formatter stringFromDate:[NSDate date]]];
        
    // Set the audio file
    NSURL *outputFileURL = [self fileUrlInDocFolderWithFileName:fileName];
    
    // Setup audio session - Removed to initializeAudioSession()
    /*
    NSError *sessionError;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
    
    if(session == nil)
        NSLog(@"Error creating session: %@", [sessionError description]);
    else
        [session setActive:YES error:nil];
    */
    
    // Settings for AVAAudioRecorder.
	NSDictionary *recordSetting = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
                                   [NSNumber numberWithFloat:samplerate], AVSampleRateKey,
                                   [NSNumber numberWithUnsignedInt:1], AVNumberOfChannelsKey,
                                   [NSNumber numberWithUnsignedInt:16], AVLinearPCMBitDepthKey,
                                   [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,
                                   [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey, nil];
    
    // Init and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.meteringEnabled = YES;
    recorder.delegate = self;
    
    [recorder recordForDuration:kMaxDuration];
    return recorder;
}

@end
