//
//  SpeakView.h
//  JuliusSample
//
//  Created by Michael Wang on 13-6-13.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface SpeakView : UIView

@property (nonatomic, assign) CGPoint circleCenter;
@property (nonatomic, assign) CGFloat circleRadius;
@property (nonatomic, assign) BOOL scaleUp;
@property (nonatomic, strong) CAShapeLayer *circle;

@end
