//
//  TestViewController.m
//  JuliusSample
//
//  Created by Matthew Magee on 12/08/2013.
//
//

#import "TestViewController.h"

#include <CoreMedia/CMBase.h>
#include <CoreFoundation/CoreFoundation.h>

#define GAIN_VALUE_UPDATE_FREQUENCY 0.05 // In Second. This value should adapt to Pitch and Bounds Arrays.

@interface TestViewController ()
- (void)juliusCallbackWithDict:(NSMutableDictionary *)wordsAndDurations;
- (void)getPitchAndASRFromURL:(NSURL*)pURL;
- (void)updateRecorderMeters;
@end

@implementation TestViewController {
    
    TestView *myView;
    TestModel *myModel;
    
    // stress/volumn/gain detecting
    NSTimer *gainValueTimer;
    NSMutableArray *gainArray;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

        //prep the view
        
        myView = [[TestView alloc] initWithFrame:self.view.bounds];
        myView.delegate = self;
        [myView configureViewReadyToRecord];
        
        self.view = myView; //assign the view to this controller
        
        //prep the model
        
        myModel = [[TestModel alloc] init];

        //invoke the SuperAudioManager singleton to ensure that any startup actions have been completed - we don't want a delay
        //when it comes to actually using this class - and also to override the genericAudioRecorder delegate to report to this class.
        
        [SuperAudioManager sharedInstance].genericAudioRecorder.delegate = self;
        
        // This is the starting point for detecting the gain/volumn/"stress"...
        // init a timer to get the gain in real-time firstly
        // -----------------------------------------------------------------
        gainValueTimer = [NSTimer scheduledTimerWithTimeInterval:GAIN_VALUE_UPDATE_FREQUENCY target:self selector:@selector(updateRecorderMeters) userInfo:nil repeats:YES];
        gainArray = [[NSMutableArray alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(juliusCallbackWithDict:) name:NotificationForJuliusCallback object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TestViewUIDelegate methods

- (void)userRequestsRecordingStart {
    
    SuperAudioManager *tempManager = [SuperAudioManager sharedInstance];
    
    if (tempManager && tempManager.genericAudioRecorder) {
        
        [tempManager micRecordingStart:tempManager.genericAudioRecorder];
        
    }

}

- (void)userRequestsRecordingEnd {
    
    SuperAudioManager *tempManager = [SuperAudioManager sharedInstance];
    
    if (tempManager && tempManager.genericAudioRecorder) {
        
        [tempManager micRecordingEnd:tempManager.genericAudioRecorder];
        
    }

}

#pragma mark - Private methods

- (void)juliusCallbackWithDict:(NSNotification*)nft {
    NSDictionary *tempDict = nft.userInfo;
    for (NSString *aWord in [tempDict allKeys]) {
        NSLog(@"%@",aWord);
    }
}

// This method doesn't have to be here in the view Controller, 'coz it's data-related.
-(void)updateRecorderMeters{
    AVAudioRecorder *theRecorder = [SuperAudioManager sharedInstance].genericAudioRecorder;
    if (theRecorder && theRecorder.meteringEnabled) {
        [theRecorder updateMeters]; /* call to refresh meter values */
//        NSLog(@"The Gain Value:%f",[[SuperAudioManager sharedInstance].genericAudioRecorder averagePowerForChannel:0]);
        [gainArray addObject:[NSNumber numberWithFloat:[theRecorder averagePowerForChannel:0]]];
    }
}


#pragma mark - AVAudioRecorderDelegate methods

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    if (flag) {
        
        //update UI to show the user we're processing the audio
        
        [myView configureViewForCalculatingResults];
        
        //threaded processing:
        [self performSelectorInBackground:@selector(getPitchAndASRFromURL:) withObject:recorder.url];
        //inline processing:
        //[self getPitchAndASRFromURL:recorder.url];
        
    }
    
}

#pragma mark - sound processing methods

- (void)getPitchAndASRFromURL:(NSURL*)pURL {
    
//    for (long loop = 0; loop < 1000000; loop++) {
//        for (long loop2 = 0; loop2 < 1000; loop2++) {
//            
//        }
//    }
    
    //extract the pitch
    
    myModel.arrayOfPitchValues = (NSMutableArray*)([[SuperAudioManager sharedInstance] extractPitchFloatArrayFromFile:pURL]);
    
    //perform the ASR pass
    
    myModel.arrayOfWords = (NSMutableDictionary*)([[SuperAudioManager sharedInstance] extractWordsFromFile:pURL]);
    
    //update the UI to show the results
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [myView configureViewForShowingResults: [myModel dumpYourLoadIntoAString]];
    });

}


@end