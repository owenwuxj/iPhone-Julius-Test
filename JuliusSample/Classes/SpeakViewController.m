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
#import "MBProgressHUD.h"

#import "TISpringLoadedSpinnerView.h"
#import "TISpringLoadedView.h"

#define SamplingRate 16000 //in Hz
#define DisplayHeight 320  //in pixel

#define ZAxisPosition -10000
#define LoadedViewLength 50

#define MODNUMBER 4

@interface SpeakViewController ()
{
	MBProgressHUD *HUD;
    
    SpeakView *speakView;
    DisplayView *displayView;
    UIView *primaryShadeView;
    
    BOOL juliusDone;
    int modNumber;

	TISpringLoadedSpinnerView * _spinnerView;
	TISpringLoadedView * _springLoadedView;
	CADisplayLink * _displayLink;
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
    
//    if (modNumber == MODNUMBER) {
        [self performSelectorInBackground:@selector(updateRMS_ZCR_ACR_Labels) withObject:nil];
//        modNumber--;
//        if (modNumber == 0) {
//            modNumber = MODNUMBER;
//        }
//    }

//    [self performSelectorOnMainThread:@selector(updateRMS_ZCR_ACR_Labels) withObject:nil waitUntilDone:NO];
}

#pragma mark -
#pragma mark Private methods

- (void)updateRMS_ZCR_ACR_Labels {
    [displayView.lineArray addObject:[NSNumber numberWithFloat:(1 - self.currentRMS) * DisplayHeight/2 - 100]];// Loglize and Replace
    [displayView.pitchLineArray addObject:[NSNumber numberWithFloat:((1 - self.currentFrequency/(rioRef.sampleRate/2))* (DisplayHeight/2))]];// Normalize and
    [displayView setNeedsDisplay];
    
    speakView.circleRadius = kMinCircleRadius + 4*self.currentRMS * (kMaxCircleRadius - kMinCircleRadius);
    speakView.offsetRadian = self.currentFrequency/50;
}

- (void)pullAnimation {
    speakView.userInteractionEnabled=YES;
    
    [UIView animateWithDuration:0.3 animations:^{
        CALayer *layer = speakView.layer;
        layer.zPosition = ZAxisPosition;
        CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
        rotationAndPerspectiveTransform.m34 = 1.0 / 500;
        layer.transform = CATransform3DRotate(rotationAndPerspectiveTransform, -10.0f * M_PI / 180.0f, 1.0f, 0.0f, 0.0f);
        
        primaryShadeView.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            speakView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            
            primaryShadeView.alpha = 0.0;
            
            displayView.frame = CGRectMake(0, speakView.frame.size.height, displayView.frame.size.width, displayView.frame.size.height);
        }];
    }];
}

- (void)pushAnimation
{
    speakView.userInteractionEnabled=NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        // show the display view
        displayView.frame = CGRectMake(0, speakView.frame.size.height - displayView.frame.size.height, displayView.frame.size.width, displayView.frame.size.height);
        [displayView setContentSize:CGSizeMake(displayView.frame.size.width*2, displayView.frame.size.height)];
        displayView.showsHorizontalScrollIndicator = YES;
        displayView.bounces = YES;
        
        // "pushing" the speak view
        CALayer *layer = speakView.layer;
        layer.zPosition = ZAxisPosition;
        
        CATransform3D rotationAndPerspectiveTransform = CATransform3DIdentity;
        rotationAndPerspectiveTransform.m34 = 1.0 / -500;
        layer.transform = CATransform3DRotate(rotationAndPerspectiveTransform, 10.0f * M_PI / 180.0f, 1.0f, 0.0f, 0.0f);
        
        // shade the shadeView
        primaryShadeView.alpha = 0.5;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            // push speak view into destination position
            speakView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            
            [self.view insertSubview:_springLoadedView aboveSubview:displayView];
            [self.view insertSubview:_spinnerView aboveSubview:_springLoadedView];

            // unshade the shadeView a bit
            primaryShadeView.alpha = 0.75;
        }];
    }];
}

- (void)recording {
	// Create file path.
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yMMddHHmmss"];
	NSString *fileName = [NSString stringWithFormat:@"%@.wav", [formatter stringFromDate:[NSDate date]]];

#if TARGET_IPHONE_SIMULATOR
//    NSArray  *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    self.filePath = [[NSString alloc] initWithFormat: @"%@/%@", [documentsDirectory stringByAppendingPathComponent:@"Recorders"], fileName];
    self.filePath = [NSString stringWithFormat:@"/Users/owenwu/Documents/%@",fileName];
#else
	self.filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
#endif
    
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
    [displayView cleanUpContext];
    
    [self recording];
    [rioRef startListening:self];
}

-(void)recordEnd {
    primaryShadeView = [[UIView alloc] initWithFrame:self.view.frame];
//    primaryShadeView.backgroundColor = [UIColor blackColor];
    
    UITapGestureRecognizer *tapOnView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pullAnimation)];
    [primaryShadeView addGestureRecognizer:tapOnView];

    [self.view insertSubview:primaryShadeView belowSubview:displayView];
    
//    while (!juliusDone) {
//        NSLog(@"%d",juliusDone);
//    }
    
//    speakView.rotationAnimation.speed = 0;
    [self pushAnimation];
    
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

- (void)displayLinkTick:(CADisplayLink *)link {
	[_spinnerView simulateSpringWithDisplayLink:link];
    //	[_springLoadedView simulateSpringWithDisplayLink:link];
}

#pragma mark -
#pragma mark View Lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
//        if (!speakView) {
            speakView = [[SpeakView alloc] initWithFrame:self.view.frame];
//        }
        
        [self.view addSubview:speakView];
//        [speakView setNeedsDisplay];

        rioRef = [RIOInterface sharedInstance];
        [rioRef initializeAudioSession];
        [rioRef setSampleRate:SamplingRate];
        
        modNumber = MODNUMBER;//used for downsampling
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordStart) name:kRecordingStartNotif object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordEnd) name:kRecordingEndNotif object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pullAnimation) name:kBackToRecordingInterface object:nil];
    
    CGRect aRect = CGRectMake((self.view.frame.size.width-LoadedViewLength)/2, self.view.frame.size.height-LoadedViewLength*1.2, LoadedViewLength, LoadedViewLength);
    _springLoadedView = [[TISpringLoadedView alloc] initWithFrame:aRect];
	[_springLoadedView setBackgroundColor:[UIColor whiteColor]];
	
	// Like the one in the Letterpress app by Loren Brichter (atebits.com)
	_spinnerView = [[TISpringLoadedSpinnerView alloc] initWithFrame:CGRectInset(aRect, 15, 15)];
	
	// Create the display link. I use one to handle all the views.
	_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTick:)];
	[_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    displayView = [[DisplayView alloc] initWithFrame:CGRectMake(0, speakView.frame.size.height, speakView.frame.size.width, speakView.frame.size.height*.5)];
    [self.view addSubview:displayView];

    displayView.hidden = false;
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
//		if (!HUD) {
//			HUD = [[MBProgressHUD alloc] initWithView:self.view];
//			HUD.labelText = @"Processing...";
////			[self.view addSubview:HUD];
//		}
//		
//        [self.view addSubview:HUD];
//		[HUD show:YES];

//		[self performSelector:@selector(recognition) withObject:nil afterDelay:0.0];
        [self performSelectorInBackground:@selector(recognition) withObject:nil];
	}
    else {
        UIAlertView *alertView= [[UIAlertView alloc] initWithTitle:@"Recording" message:@"File Not Saved" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#pragma mark -
#pragma mark Julius delegate

- (void)callBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry{
//    [HUD hide:YES];
    
    for (id aView in self.view.subviews) {
        if ([aView isKindOfClass:[TISpringLoadedSpinnerView class]] || [aView isKindOfClass:[TISpringLoadedView class]]) {
            [aView removeFromSuperview];
        }
    }
    
	// Show results.
//	textView.text = [results componentsJoinedByString:@""];
    NSLog(@"Show Results: %@ /n has %d bounds",[results componentsJoinedByString:@""], [boundsAry count]);
    
    juliusDone = YES;
    
    displayView.textArray = [NSMutableArray arrayWithArray:results];
    displayView.boundsArray = [NSMutableArray arrayWithArray:boundsAry];
    [displayView addTextLabelsToView];
}

@end