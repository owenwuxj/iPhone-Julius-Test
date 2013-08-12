//
//  TestViewController.h
//  JuliusSample
//
//  Created by Matthew Magee on 12/08/2013.
//
//

#import <UIKit/UIKit.h>

#import "TestView.h"
#import "TestModel.h"

#import "SuperAudioManager.h"

@interface TestViewController : UIViewController <AVAudioRecorderDelegate, TestViewUIDelegate>

@end
