//
//  SpeakView.h
//  JuliusSample
//
//  Created by Michael Wang on 13-6-13.
//
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "TTTAttributedLabel.h"

#define kMinCircleRadius 60
#define kMaxCircleRadius 150

#define kRecordingStartNotif @"RecordingStartNotif"
#define kRecordingEndNotif @"RecordingEndNotif"

@interface SpeakView : UIView

@property (nonatomic, assign) CGPoint circleCenter;
@property (nonatomic, assign) CGFloat circleRadius;
@property (nonatomic, assign) BOOL scaleUp;
@property (nonatomic, strong) CAShapeLayer *circleOne;
@property (nonatomic, strong) CAShapeLayer *circleTwo;
@property (nonatomic, strong) CAShapeLayer *circleThree;
@property (nonatomic, strong) CAShapeLayer *innerCircle;

@property (nonatomic, strong) TTTAttributedLabel *label;
@property (nonatomic, assign) BOOL isStarted;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) UIButton *btnSpeak;

@property (nonatomic, strong) CABasicAnimation* rotationAnimation;
@property (nonatomic, strong) UIImageView *ivCenter;
@property (nonatomic, assign) CFTimeInterval rotateSpeed;

@end
