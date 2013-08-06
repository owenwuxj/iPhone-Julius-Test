//
//  JuliusSampleAppDelegate.m
//  JuliusSample
//
//  Created by Watanabe Toshinori on 11/01/15.
//  Copyright 2011 FLCL.jp. All rights reserved.
//

#import "JuliusSampleAppDelegate.h"

#define kSamplingRate 16000.0 //Sampling Frequency in Hz
#define GAIN_VALUE_UPDATE_FREQUENCY 0.05//In Second


#define GET_PITCH 1
#define REAL_TIME 0 // not working for now

@implementation JuliusSampleAppDelegate

@synthesize window, resultText, notificationLabel;

#pragma mark -
#pragma mark Private Methods

// Get the /Library/PrivateDocuments folder, create one if no.
-(NSString *)applicationLibraryPrivateDocument{
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *priAppDir = [libDir stringByAppendingPathComponent:kPrivateAppDir];
    if (![[NSFileManager defaultManager] fileExistsAtPath:priAppDir]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:priAppDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"FAILED TO CREATE %@",priAppDir);
        }
    }
    return priAppDir;
}

// If you need the Gain/Volumn/Stress values, make an array to hold the values from this method
-(void)updateRecorderMeters{
    if (aRecorder && aRecorder.meteringEnabled) {
        [aRecorder updateMeters];
        NSLog(@"The Gain Value:%f",[aRecorder averagePowerForChannel:0]);
    }
}

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch.
    
    // This is the starting point for detecting the gain/volumn/"stress"...
    // init a timer to get the gain in real-time firstly
    // -----------------------------------------------------------------
    gainValueTimer = [NSTimer scheduledTimerWithTimeInterval:GAIN_VALUE_UPDATE_FREQUENCY target:self selector:@selector(updateRecorderMeters) userInfo:nil repeats:YES];
    
    // Init and start the common tasks for non real-time audio
    // -----------------------------------------------------------------
    [[MyAudioManager sharedInstance] setSampleRate:kSamplingRate];
    [[MyAudioManager sharedInstance] initializeAudioSession];

//    if (GET_PITCH) {
        // This is the starting point for using Julius/Speech Recognition
        // Use Macro to change between real-time or offline modes
        // -----------------------------------------------------------------
//        [[MyAudioManager sharedInstance] setAubioORjulius:LIBAUBIO];
        [[MyAudioManager sharedInstance] setDelegateAubio:self];
#if REAL_TIME
        [[MyAudioManager sharedInstance] setIsRealTime:YES];
        [[MyAudioManager sharedInstance] startListening:self];
#else
        [[MyAudioManager sharedInstance] setIsRealTime:NO];
        aRecorder = [[MyAudioManager sharedInstance] getRecorderForAubio];
        [aRecorder record];
#endif
//    } else {
        // This is the starting point for using Aubio/Pitch & ADSR & Tempo Tracking
        // Use Macro to change between real-time or offline modes
        // -----------------------------------------------------------------
//        [[MyAudioManager sharedInstance] setAubioORjulius:LIBJULIUS];
        [[MyAudioManager sharedInstance] setDelegateJulius:self];
#if REAL_TIME
        [[MyAudioManager sharedInstance] isRealTime] = YES;
        [[MyAudioManager sharedInstance] startListening:self]; if real time YES
#else
        [[MyAudioManager sharedInstance] setIsRealTime:NO];
        jRecorder = [[MyAudioManager sharedInstance] getRecorderForJulius];
        [jRecorder record];
#endif
//    }
    
    // Add the view controller's view to the window and display.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

#pragma mark -
#pragma mark juliusManagerDelegate and aubioManagerDelegate Methods

- (void)juliusCallBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry{
    NSMutableString *juliusResults = [[NSMutableString alloc] init];
    [juliusResults appendFormat:@"\n%d Words: ", [results count]];
    for (NSString *temp in results) {
        NSLog(@"In results:%@",temp);
        [juliusResults appendString:temp];
    }
    [juliusResults appendString:@"\nThe Durations(in frame):"];
    for (NSNumber *aNum in boundsAry) {
        NSLog(@"In boundsAry:%d", [aNum intValue]);
        [juliusResults appendFormat:@"<%d>",[aNum intValue]];
    }
    
    jRecorder.meteringEnabled = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        resultText.text = [NSString stringWithString:juliusResults];
    });
}

- (void)aubioCallBackResult:(NSArray *)results{
    notificationLabel.text = @"Pitch & Gain Values in the LOG.";
    for (int idx=0; idx<[results count]; idx++) {
        NSLog(@"In pitchArray[%d]:%f",idx, [results[idx] floatValue]);
    }
    aRecorder.meteringEnabled = NO;
}

@end
