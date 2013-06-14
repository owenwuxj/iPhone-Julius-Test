//
//  SpeakViewController.m
//  JuliusSample
//
//  Created by Michael Wang on 13-6-8.
//
//

#import "SpeakViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "SpeakView.h"
#import "DisplayView.h"

#define SamplingRate 16000 //in Hz
#define DisplayHeight 320  //in pixel

@interface SpeakViewController ()
{
    SpeakView *speakView;
    DisplayView *displayView;
}
@property(nonatomic, assign) float currentFrequency;
@property(nonatomic, assign) float currentFrequencyACF;
@property(nonatomic, assign) float currentFrequencyZCR;
@property(nonatomic, assign) float currentRMS;
@end

@implementation SpeakViewController

@synthesize filePath;

#pragma mark -
#pragma mark Public methods

- (void)frequencyChangedWithRMS:(float)newRMS withACF:(float)newACF andZCR:(float)newZCR withFreq:(float)newFreq {
	self.currentRMS = newRMS;
    self.currentFrequencyACF = newACF;
    self.currentFrequencyZCR = newZCR;
    self.currentFrequency = newFreq;
	[self performSelectorInBackground:@selector(updateRMS_ZCR_ACR_Labels) withObject:nil];
//    [self performSelectorOnMainThread:@selector(updateRMS_ZCR_ACR_Labels) withObject:nil waitUntilDone:NO];
}

- (void)updateRMS_ZCR_ACR_Labels {
    [displayView.lineArray addObject:[NSNumber numberWithFloat:(1 - self.currentRMS) * DisplayHeight/2 - 100]];// Loglize and Replace
    [displayView.pitchLineArray addObject:[NSNumber numberWithFloat:((1 - self.currentFrequency/(rioRef.sampleRate/2))* (DisplayHeight/2))]];// Normalize and
    [displayView setNeedsDisplay];
    
    speakView.circleRadius = kMinCircleRadius + 4*self.currentRMS * (kMaxCircleRadius - kMinCircleRadius);
//    [speakView setNeedsDisplay];

}

- (void)updateSpeakView {
    if (!speakView) {
        speakView = [[SpeakView alloc] initWithFrame:self.view.frame];
    }
    
    [self.view addSubview:speakView];
    [speakView setNeedsDisplay];
}

- (void)recording {
	// Create file path.
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yMMddHHmmss"];
	NSString *fileName = [NSString stringWithFormat:@"%@.wav", [formatter stringFromDate:[NSDate date]]];
    
	self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
//    self.filePath = [NSURL fileURLWithPath:@"/dev/null"];
    
	// Change Audio category to Record.
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    
	// Settings for AVAAudioRecorder.
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM], AVFormatIDKey,
							  [NSNumber numberWithFloat:16000.0], AVSampleRateKey,
							  [NSNumber numberWithUnsignedInt:1], AVNumberOfChannelsKey,
							  [NSNumber numberWithUnsignedInt:16], AVLinearPCMBitDepthKey,
							  [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
							  nil];
    
    NSError *err;
	recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:filePath] settings:settings error:&err];
	recorder.delegate = self;
    
    if (err) {
        NSLog(@"%@",err);
    }
    
	[recorder prepareToRecord];
	[recorder record];
}

-(void)recordStart {
    [self recording];
    [rioRef startListening:self];
}

-(void)recordEnd {
    displayView = [[DisplayView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:displayView];

    [recorder stop];
    [rioRef stopListening];
}

- (void)recognition {
	if (!julius) {
		julius = [Julius new];
		julius.delegate = self;
	}
    else {// Owen 20130607: Init Julius every time starting recognition
        julius = nil;
        julius = [Julius new];
        julius.delegate = self;
    }
    
    NSLog(@"filePath is %@",filePath);
	[julius recognizeRawFileAtPath:filePath];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        [self updateSpeakView];

        rioRef = [RIOInterface sharedInstance];
        [rioRef initializeAudioSession];
        [rioRef setSampleRate:SamplingRate];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
//    NSLog(@"Random Number: %d",(arc4random()%100));
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordStart) name:kRecordingStartNotif object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordEnd) name:kRecordingEndNotif object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSpeakView) name:kBackToRecordingInterface object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)shouldAutorotate{
    return NO;
}

#pragma mark -
#pragma mark AVAudioRecorder delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
	if (flag) {
		[self performSelector:@selector(recognition) withObject:nil afterDelay:0.0];
	}
    else {
        UIAlertView *alertView= [[UIAlertView alloc] initWithTitle:@"Recording" message:@"File Not Saved" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#pragma mark -
#pragma mark Julius delegate

- (void)callBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry{
	// Show results.
//	textView.text = [results componentsJoinedByString:@""];
    NSLog(@"Show Results: %@ /n has %d bounds",[results componentsJoinedByString:@""], [boundsAry count]);
    
    displayView.textArray = [NSMutableArray arrayWithArray:results];
    displayView.boundsArray = [NSMutableArray arrayWithArray:boundsAry];
    [displayView setNeedsDisplay];
}

@end