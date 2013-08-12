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

@interface TestViewController ()

@end

@implementation TestViewController {
    
    TestView *myView;
    TestModel *myModel;
    
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


#pragma mark - AVAudioRecorderDelegate methods

/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    
    if (flag) {
        
        //update UI to show the user we're processing the audio
        
        [myView configureViewForCalculatingResults];
        
        //extract the pitch
        
        myModel.arrayOfPitchValues = (NSMutableArray*)([[SuperAudioManager sharedInstance] extractPitchFloatArrayFromFile:recorder.url]);
        
        //perform the ASR pass
        
        //...
        
        //update the UI to show the results
        
        [myView configureViewForShowingResults: [myModel dumpYourLoadIntoAString]];
        
        
    }
    
}


@end
