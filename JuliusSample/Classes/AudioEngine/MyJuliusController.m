//
//  MyJuliusController.m
//  JuliusSample
//
//  Created by OwenWu on 05/08/2013.
//
//

#import "MyJuliusController.h"

@implementation MyJuliusController

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
    [self performSelectorInBackground:@selector(initializeJuliusWithRecorder:) withObject:theRecorder];
//    [self initializeJuliusWithRecorder:theRecorder];
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
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
    if (self.controllerDelegateJulius) {
        [self.controllerDelegateJulius juliusCallBackResult:results withBounds:boundsAry];
    }
}

@end

