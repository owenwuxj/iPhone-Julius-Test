//
//  SpeakViewController.h
//  JuliusSample
//
//  Created by Michael Wang on 13-6-8.
//
//

#import <UIKit/UIKit.h>

#import <AVFoundation/AVFoundation.h>

#import "RIOInterface.h"
#import "Julius.h"

@interface SpeakViewController : UIViewController <AVAudioRecorderDelegate, JuliusDelegate> {
  
    AVAudioRecorder *recorder;
	Julius *julius;
    RIOInterface *rioRef;

}

@property (nonatomic, strong) NSString *filePath;

- (void)frequencyChangedWithRMS:(float)newRMS withACF:(float)newACF andZCR:(float)newZCR withFreq:(float)newFreq;

@end