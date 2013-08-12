//
//  TestView.m
//  JuliusSample
//
//  Created by Matthew Magee on 12/08/2013.
//
//

#import "TestView.h"

@implementation TestView {
    
    UIView *recordingContainer;
    UIView *processingContainer;
    UIView *resultsContainer;
    
    UIButton *startButton;
    UIButton *stopButton;
    
    UITextView *resultsText;
    
    
    
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.backgroundColor = [UIColor lightGrayColor];
        
        //
        
        recordingContainer = [[UIView alloc] initWithFrame:self.bounds];
        
        startButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        startButton.frame = CGRectMake(20, 20, self.frame.size.width-40, 50);
        [startButton setTitle:@"Start Recording" forState:UIControlStateNormal];
        [startButton addTarget:self action:@selector(startPressed) forControlEvents:UIControlEventTouchUpInside];
        
        stopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        stopButton.frame = CGRectMake(20, 90, self.frame.size.width-40, 50);
        [stopButton setTitle:@"Stop Recording" forState:UIControlStateNormal];
        [stopButton addTarget:self action:@selector(stopPressed) forControlEvents:UIControlEventTouchUpInside];
        
        startButton.userInteractionEnabled = YES;
        stopButton.userInteractionEnabled  = NO;
        
        [recordingContainer addSubview:startButton];
        [recordingContainer addSubview:stopButton];
        
        //
        
        processingContainer = [[UIView alloc] initWithFrame:self.bounds];
        
        UILabel *someLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 50)];
        someLabel.text = @"Processing your audio.";
        
        [processingContainer addSubview:someLabel];
        
        //
        
        resultsContainer = [[UIView alloc] initWithFrame:self.bounds];
        
        resultsText = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height*0.8f)];
        
        resultsText.text = @"Results will go here.";
        
        UIButton *restartButton;
        
        restartButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        restartButton.frame = CGRectMake(20, self.frame.size.height*0.8f+10.0f, self.frame.size.width-40, 50);
        [restartButton setTitle:@"Restart" forState:UIControlStateNormal];
        [restartButton addTarget:self action:@selector(restartPressed) forControlEvents:UIControlEventTouchUpInside];
        
        [resultsContainer addSubview:resultsText];
        [resultsContainer addSubview:restartButton];
        
        //add all of the containers to this view
        
        [self addSubview:recordingContainer];
        
        [self addSubview:processingContainer];
        
        [self addSubview:resultsContainer];
        
    }
    return self;
}

- (void)startPressed {
    if (self.delegate) {
        [self.delegate userRequestsRecordingStart];
        //stop user from pressing start again, enable stop
        startButton.userInteractionEnabled = NO;
        stopButton.userInteractionEnabled  = YES;
    }
}

- (void)stopPressed {
    if (self.delegate) {
        [self.delegate userRequestsRecordingEnd];
        //disable all interaction until the view is configured to record again
        startButton.userInteractionEnabled = NO;
        stopButton.userInteractionEnabled  = NO;
    }
}

- (void)restartPressed {
    [self configureViewReadyToRecord];
}

#pragma mark - public methods

- (void)configureViewReadyToRecord {
    
    recordingContainer.hidden = NO;
    processingContainer.hidden = YES;
    resultsContainer.hidden = YES;
    
    //buttons in recording configuration
    startButton.userInteractionEnabled = YES;
    stopButton.userInteractionEnabled  = NO;
    
}

- (void)configureViewForCalculatingResults {
    
    recordingContainer.hidden = YES;
    processingContainer.hidden = NO;
    resultsContainer.hidden = YES;
    
}

- (void)configureViewForShowingResults:(NSString*)pResultsString {
    
    recordingContainer.hidden = YES;
    processingContainer.hidden = YES;
    resultsContainer.hidden = NO;
    
    resultsText.text = pResultsString;
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
