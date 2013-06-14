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

@interface SpeakViewController ()
{
    SpeakView *speakView;
}
@end 

@implementation SpeakViewController

@synthesize filePath;

- (void)recording
{
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

-(void)recordStart
{
    NSLog(@"Started");
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self)
    {
        speakView = [[SpeakView alloc] initWithFrame:self.view.frame];
        [self.view addSubview:speakView];
        [self.view setNeedsDisplay];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSLog(@"Random Number: %d",(arc4random()%100)+1);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordStart) name:kRecordingStartNotif object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark AVAudioRecorder delegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
	if (flag) {
		[self performSelector:@selector(recognition) withObject:nil afterDelay:0.1];
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
    NSLog(@"Show Results: %@",[results componentsJoinedByString:@""]);
    
//    theView.textArray = [NSMutableArray arrayWithArray:results];
//    theView.boundsArray = [NSMutableArray arrayWithArray:boundsAry];
//    [theView setNeedsDisplay];
}

@end