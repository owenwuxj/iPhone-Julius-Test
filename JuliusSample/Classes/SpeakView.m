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

#define kInnerCircleBgColor [UIColor colorWithRed:51/255.0 green:144/255.0 blue:211/255.0 alpha:1.0]
#define kViewBgColor [UIColor colorWithRed:92/255.0 green:183/255.0 blue:236/255.0 alpha:1.0]

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
            offsetRadian;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _isStarted = NO;
        [self setBackgroundColor:kViewBgColor];
        
        self.offsetRadian = 1;

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
        NSTimer *repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animateCircle) userInfo:nil repeats:YES];
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

- (UIBezierPath *)makeArcWithradius:(CGFloat)radius startRadian:(CGFloat)startRadian endRadian:(CGFloat)endRadian clockwise:(BOOL)isBottomHalf
{
    CGFloat startAngle = [self degreeToRadian:startRadian];
    CGFloat endAngle = [self degreeToRadian:endRadian];
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
 
    circleOne.path = [self makeArcWithradius:self.circleRadius startRadian:self.offsetRadian + 0.0f endRadian:self.offsetRadian + 60.0f clockwise:YES].CGPath;
    [circleOne addAnimation:pathAnimation forKey:@"changePathAnimation"];
    
    circleTwo.path = [self makeArcWithradius:self.circleRadius startRadian:self.offsetRadian + 120.0f endRadian:self.offsetRadian + 180.0f clockwise:YES].CGPath;
    [circleTwo addAnimation:pathAnimation forKey:@"changePathAnimation"];
    
    circleThree.path = [self makeArcWithradius:self.circleRadius startRadian:self.offsetRadian - 60.0f endRadian:self.offsetRadian - 120.0f clockwise:NO].CGPath;
    [circleThree addAnimation:pathAnimation forKey:@"changePathAnimation"];
}

- (void)animateCircle
{
    if (self.circleRadius == kMinCircleRadius){
        self.scaleUp = YES;
    } else if (self.circleRadius == kMaxCircleRadius){
        self.scaleUp = NO;
    }
    
    if (self.scaleUp)
    {
        self.circleRadius += 1;
        self.offsetRadian += 1;
    } else {
        self.circleRadius -= 1;
        self.offsetRadian -= 1;
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
