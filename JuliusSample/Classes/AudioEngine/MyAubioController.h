//
//  MyAubioController.h
//  JuliusSample
//
//  Created by OwenWu on 05/08/2013.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#include "aubio.h"

@protocol aubioControllerDelegate;

@interface MyAubioController : NSObject <AVAudioRecorderDelegate>
@property(nonatomic, weak) id<aubioControllerDelegate> controllerDelegateAubio;
@end

@protocol aubioControllerDelegate
- (void)aubioCallBackResult:(NSArray *)results;
@end
