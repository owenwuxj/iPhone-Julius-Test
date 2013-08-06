//
//  MyAubioController.m
//  JuliusSample
//
//  Created by OwenWu on 05/08/2013.
//
//

#import "MyAubioController.h"

#include "utils.h"

//#define kFrameNumberInTheFile 1000

unsigned int pos = 0; /*frames%dspblocksize*/
aubio_source_t *that_source = NULL;

/* pitch objects */
aubio_pitch_t *pitchObject;
fvec_t *pitch;

typedef struct {
    float *arrayData;
    size_t used;
    size_t size;
} GrowingFloatArrayPureC;

//------------------------------------------------------------------------------------------
// All the staff I need to store the C array for pitch value and pass it to Objectvive-C
float *pitchArray;
GrowingFloatArrayPureC pArray;

void initArray(GrowingFloatArrayPureC *a, size_t initialSize) {
    a->arrayData = (float *)malloc(initialSize * sizeof(float));
    a->used = 0;
    a->size = initialSize;
}

void insertArray(GrowingFloatArrayPureC *a, float element) {
    if (a->used == a->size) {
        a->size *= 2;// This is interesting
        a->arrayData = (float *)realloc(a->arrayData, a->size * sizeof(float));
    }
    a->arrayData[a->used++] = element;
}

void freeArray(GrowingFloatArrayPureC *a) {
    free(a->arrayData);
    a->arrayData = NULL;
    a->used = a->size = 0;
}
//------------------------------------------------------------------------------------------


@implementation MyAubioController

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
//    outmsg("Time:%f Freq:%f\n",(frames)*overlap_size/(float)samplerate, pitch_found);
    
    pitchArray[frames] = pitch_found;//the array holding pitch values
    insertArray(&pArray, pitch_found);  // automatically resizes as necessary
    //    NSLog(@"pitchArray[%d]:%f",frames, pitchArray[frames]);
    
    //    smpl_t onset_found = fvec_read_sample (onset, 0);
    //    if (onset_found) {
    //        outmsg ("Onset:%f\n", aubio_onset_get_last_s (onsetObject) );
    //    }
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
    
    // ...
//    pitchArray = (float *)malloc(sizeof(float)*kFrameNumberInTheFile);
    initArray(&pArray, 5);  // initially 5 elements
    
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
    
    //    del_aubio_pitch (pitchObject);
    //    del_fvec (pitch);
    //    del_aubio_onset(onsetObject);
    //    del_fvec(onset);
    
#ifdef DEBUG
    //    DLog(@"pitchArray cnt: %d", [self.pitchArray count]);
#endif
    
//    NSMutableArray *tempPitch = [NSMutableArray arrayWithCapacity:kFrameNumberInTheFile];
//    for (int idx=0; idx<kFrameNumberInTheFile; idx++) {
//        [tempPitch addObject:[NSNumber numberWithFloat:pitchArray[idx]]];
        //        NSLog(@"pitchArray[%d]:%f",idx, pitchArray[idx]);
//    }
    
    NSMutableArray *tempPitch2 = [NSMutableArray array];
    for (int idx = 0; idx<pArray.size; idx++) {
        [tempPitch2 addObject:[NSNumber numberWithFloat:pArray.arrayData[idx]]];
    }
    
    if (self.controllerDelegateAubio) {
        [self.controllerDelegateAubio aubioCallBackResult:tempPitch2];
    }
    
    examples_common_del();
    debug("End of program.\n");
    fflush(stderr);
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

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)theRecorder successfully:(BOOL)flag
{
    [self initializeAubioWithRecorder:theRecorder];
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

@end
