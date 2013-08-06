//
//  MyJuliusController.h
//  JuliusSample
//
//  Created by OwenWu on 05/08/2013.
//
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "Julius.h"

@protocol juliusControllerDelegate;

@interface MyJuliusController : NSObject <AVAudioRecorderDelegate, JuliusDelegate>
{
	Julius *julius;
}

@property(nonatomic, weak) id<juliusControllerDelegate> controllerDelegateJulius;

@end

@protocol juliusControllerDelegate

- (void)juliusCallBackResult:(NSArray *)results withBounds:(NSArray *)boundsAry;

@end

