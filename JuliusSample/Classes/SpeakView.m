//
//  SpeakView.m
//  JuliusSample
//
//  Created by Michael Wang on 13-6-13.
//
//

#import "SpeakView.h"
#import "TTTAttributedLabel.h"
#import <CoreText/CoreText.h>
#import "DisplayView.h"

#define RGBCOLOR(r,g,b) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:1]
#define kInnerCircleBgColor RGBCOLOR(51, 144, 211)
#define kViewBgColor RGBCOLOR(92, 183, 236)
#define kFriction 1.5f

@implementation SpeakView

@synthesize circleCenter,
            circleRadius,
            scaleUp,
            label,
            isStarted = _isStarted,
            timer,
            btnSpeak,
            circleOne,
            circleTwo,
            circleThree,
            ivCenter,
            innerCircle,
            offsetDegree;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _isStarted = NO;
        [self setBackgroundColor:kViewBgColor];
        
        self.offsetDegree = 1.0f;

        self.circleCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
        self.circleRadius = kMinCircleRadius;
        [self initInnerCircle];
        
        circleOne = [self createCircle];
        circleTwo = [self createCircle];
        circleThree = [self createCircle];
        
        [self initButton];
    }
    
    return self;
}

- (void)initButton
{
    btnSpeak = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 60, self.frame.size.width, 60)];
    btnSpeak.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 20, 0);
    [btnSpeak setTitle:@"Hold to talk" forState:UIControlStateNormal];
    [btnSpeak setTitle:@"Release to stop" forState:UIControlEventTouchDown];

    [btnSpeak setBackgroundColor:kInnerCircleBgColor];
    [btnSpeak addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
    [btnSpeak addTarget:self action:@selector(touchUpInside) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:btnSpeak];
}

- (void)initInnerCircle
{
    ivCenter = [[UIImageView alloc] initWithFrame:CGRectMake(self.circleCenter.x - self.circleRadius, self.circleCenter.y - self.circleRadius, self.circleRadius * 2, self.circleRadius * 2)];
    [ivCenter setBackgroundColor:kInnerCircleBgColor];
    
    UIImage *image = [UIImage imageNamed:@"rotate"];
    ivCenter.layer.cornerRadius = 60;
    ivCenter.layer.masksToBounds = YES;
    ivCenter.image = image;
    [self addSubview:ivCenter];
}

- (void)touchDown
{    
    if (!self.isStarted)
    {
        [self.timer invalidate];
        NSTimer *repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60 target:self selector:@selector(animateCircle) userInfo:nil repeats:YES];
        self.timer = repeatingTimer;
        
        self.isStarted = YES;        
        [[NSNotificationCenter defaultCenter] postNotificationName:kRecordingStartNotif object:nil];
    }
}

- (void)touchUpInside
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kRecordingEndNotif object:nil];
    
    [self.timer invalidate];
    self.timer = nil;
    
    self.isStarted = NO;
}

- (CAShapeLayer *)createCircle
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    
    // Configure the apperence of the circle
    circle.fillColor = [UIColor colorWithRed:198/255.0 green:236/255.0 blue:252/255.0 alpha:1.0].CGColor;
    circle.strokeColor = [UIColor colorWithRed:198/255.0 green:236/255.0 blue:252/255.0 alpha:1.0].CGColor;
    circle.lineWidth = 1;
    
    // Add to parent layer
    [self.layer addSublayer:circle];
    
    return circle;
}

- (UIBezierPath *)makeCircleAtLocation:(CGPoint)location radius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:location
                    radius:radius
                startAngle:0.0
                  endAngle:M_PI * 2
                 clockwise:YES];
    
    return path;
}

- (CGFloat)degreeToRadian:(float)degree
{
    return ((degree / 180.0f) * M_PI);
}

- (UIBezierPath *)makeArcWithradius:(CGFloat)radius startDegree:(CGFloat)startDegree endDegree:(CGFloat)endDegree clockwise:(BOOL)isBottomHalf
{
    CGFloat startAngle = [self degreeToRadian:startDegree];
    CGFloat endAngle = [self degreeToRadian:endDegree];
    CGPoint center = self.circleCenter;
    
//    CGPoint point = CGPointMake(center.x + radius * cosf(startRadian), center.y + radius * sinf(startRadian));
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:center];
//    [path addLineToPoint:point];
    [path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:isBottomHalf];
    [path closePath];
    
    return path;
}

- (void)drawCircleWithRadius:(CGFloat)radius
{
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
    
    [pathAnimation setDuration:0.05];
    [pathAnimation setRepeatCount:1.0f];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
 
    circleOne.path = [self makeArcWithradius:self.circleRadius startDegree:self.offsetDegree + 0.0f endDegree:self.offsetDegree + 60.0f clockwise:YES].CGPath;
    [circleOne addAnimation:pathAnimation forKey:@"changePathAnimation"];
    
    circleTwo.path = [self makeArcWithradius:self.circleRadius startDegree:self.offsetDegree + 120.0f endDegree:self.offsetDegree + 180.0f clockwise:YES].CGPath;
    [circleTwo addAnimation:pathAnimation forKey:@"changePathAnimation"];
    
    circleThree.path = [self makeArcWithradius:self.circleRadius startDegree:self.offsetDegree - 60.0f endDegree:self.offsetDegree - 120.0f clockwise:NO].CGPath;
    [circleThree addAnimation:pathAnimation forKey:@"changePathAnimation"];
}

- (void)animateCircle
{
    if (self.circleRadius == kMinCircleRadius){
        self.scaleUp = YES;
    } else if (self.circleRadius == kMaxCircleRadius){
        self.scaleUp = NO;
    }
    
    if (self.offsetDegree > 0.0f) {
        self.offsetDegree -= kFriction;
    }
        
    if (self.offsetDegree < 0.0f) {
        self.offsetDegree = 0.0f;
    }
    
    self.offsetDegree += 1.2f;
    
    if (self.scaleUp)
    {
        self.circleRadius -= kFriction;
        self.circleRadius += 1;
    } else {
        self.circleRadius += kFriction;
        self.circleRadius -= 1;
    }
    
    [self drawCircleWithRadius:circleRadius];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}

@end
