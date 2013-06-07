//
//  JuliusSampleViewController.m
//  JuliusSample
//
//  Created by Watanabe Toshinori on 11/01/15.
//  Copyright 2011 FLCL.jp. All rights reserved.
//

#import "JuliusSampleViewController.h"
#import "DisplayView.h"
#import "RIOInterface.h"

@interface JuliusSampleViewController ()
- (void)recording;
- (void)recognition;
@end

#define DisplayHeight 320  //in pixel
#define SamplingRate 32000 //in Hz

@implementation JuliusSampleViewController

@synthesize recordButton;
@synthesize textView;
@synthesize HUD;
@synthesize recorder;
@synthesize julius;
@synthesize filePath;
@synthesize processing;

@synthesize currentFrequency,currentFrequencyACF,currentFrequencyZCR,currentRMS;

#pragma mark -
#pragma mark Actions

- (IBAction)startOrStopRecording:(id)sender {
	if (!processing) {
		[self recording];
		[recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        
        [theView cleanUpContext];
        [rioRef startListening:self];

	} else {
		[recorder stop];
		[recordButton setTitle:@"Record" forState:UIControlStateNormal];
        
        [rioRef stopListening];
        
	}
	self.processing = !processing;
}

#pragma mark -
#pragma mark Private methods

- (void)recording {
	// Create file path.
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yMMddHHmmss"];
	NSString *fileName = [NSString stringWithFormat:@"%@.wav", [formatter stringFromDate:[NSDate date]]];
	[formatter release];

	self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];

	// Change Audio category to Record.
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];

	// Settings for AVAAudioRecorder.
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
							  [NSNumber numberWithFloat:16000.0], AVSampleRateKey,
							  [NSNumber numberWithUnsignedInt:1], AVNumberOfChannelsKey,
							  [NSNumber numberWithUnsignedInt:16], AVLinearPCMBitDepthKey,
//							  [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
							  nil];

    NSError *err;
	self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:filePath] settings:settings error:&err];
	recorder.delegate = self;
    
    if (err) {
        NSLog(@"%@",err);
    }

	[recorder prepareToRecord];
	[recorder record];
}

- (void)recognition {
	if (!self.julius) {
		self.julius = [Julius new];
		julius.delegate = self;
	}
	
	[julius recognizeRawFileAtPath:filePath];
}

- (void)frequencyChangedWithRMS:(float)newRMS withACF:(float)newACF andZCR:(float)newZCR withFreq:(float)newFreq{
//	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	self.currentRMS = newRMS;
    self.currentFrequencyACF = newACF;
    self.currentFrequencyZCR = newZCR;
    self.currentFrequency = newFreq;
	[self performSelectorInBackground:@selector(updateRMS_ZCR_ACR_Labels) withObject:nil];
//	[pool drain];
//	pool = nil;
}

- (void)updateRMS_ZCR_ACR_Labels {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    [theView.lineArray addObject:[NSNumber numberWithFloat:(1 - self.currentRMS) * DisplayHeight/2 - 100]];// Loglize and Replace
    [theView.pitchLineArray addObject:[NSNumber numberWithFloat:((1 - self.currentFrequency/(rioRef.sampleRate/2))* (DisplayHeight/2))]];// Normalize and Placement
//    [theView.pitchLineArray addObject:[NSNumber numberWithFloat:(1 - self.currentFrequencyACF) * DisplayHeight / 100 + 150]];
    [theView setNeedsDisplay];
    
    /*
	self.currentRMSLabel.text = [NSString stringWithFormat:@"%f", self.currentRMS];
	[self.currentRMSLabel setNeedsDisplay];
    
    self.currentPitchACFLabel.text = [NSString stringWithFormat:@"%f", self.currentFrequencyACF];
    [self.currentPitchACFLabel setNeedsDisplay];
    
    self.currentPitchZCRLabel.text = [NSString stringWithFormat:@"%f", self.currentFrequencyZCR];
    [self.currentPitchZCRLabel setNeedsDisplay];
    
	self.currentPitchLabel.text = [NSString stringWithFormat:@"%f", self.currentFrequency];
	[self.currentPitchLabel setNeedsDisplay];
    */
     
	[pool drain];
	pool = nil;
}

#pragma mark -
#pragma mark Lifecycle
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
	rioRef = [RIOInterface sharedInstance];
    [rioRef initializeAudioSession];
    [rioRef setSampleRate:SamplingRate];
    
    theView = [[DisplayView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2, self.view.frame.size.width, self.view.frame.size.height/2)];
    [self.view addSubview:theView];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
//	currentPitchLabel = nil;
//    listenButton = nil;
    
    [super viewDidUnload];
}

-(BOOL)shouldAutorotate{
    return NO;
}

#pragma mark -
#pragma mark AVAudioRecorder delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
	if (flag) {
		if (!HUD) {
			self.HUD = [[[MBProgressHUD alloc] initWithView:self.view] autorelease];
			HUD.labelText = @"Processing...";
			[self.view addSubview:HUD];
		}
		
		[HUD show:YES];
		
		[self performSelector:@selector(recognition) withObject:nil afterDelay:0.1];
	}
    else {
        UIAlertView *alertView= [[UIAlertView alloc] initWithTitle:@"Recording" message:@"File Not Saved" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
    }
}

#pragma mark -
#pragma mark Julius delegate

- (void)callBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry{
	[HUD hide:YES];

	// Show results.
	textView.text = [results componentsJoinedByString:@""];
    
    theView.boundsArray = [NSMutableArray arrayWithArray:boundsAry];
    [theView setNeedsDisplay];
}

#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	self.recorder = nil;
	self.julius = nil;
    self.filePath = nil;
	
	self.recordButton = nil;
	self.textView = nil;
	self.HUD = nil;

    if (theView) {
        [theView release];
        theView = nil;
    }

    [super dealloc];
}

@end
