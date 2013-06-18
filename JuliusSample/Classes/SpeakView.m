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
            circleThree;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self)
    {
        _isStarted = NO;
        [self setBackgroundColor:[UIColor colorWithRed:92/255.0 green:183/255.0 blue:236/255.0 alpha:1.0]];

        self.circleCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
        self.circleRadius = kMinCircleRadius;
        [self drawInnerCircle];
        circleOne = [self createCircle];
//        circleTwo = [self createCircle];
//        circleThree = [self createCircle];
        
        circleOne.frame = CGRectMake(self.circleCenter.x, self.circleCenter.y, self.circleRadius, self.circleRadius);

        CABasicAnimation* rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        //    rotationAnimation.fromValue = [innerCircle valueForKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
        rotationAnimation.duration = 5.0;
        rotationAnimation.repeatCount = FLT_MAX;
        rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]; 
        [circleOne addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        
        btnSpeak = [[UIButton alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 60, self.frame.size.width, 60)];

        [btnSpeak setTitle:@"Hold to talk" forState:UIControlStateNormal];
        [btnSpeak setBackgroundColor:kInnerCircleBgColor];
        [btnSpeak addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
        [btnSpeak addTarget:self action:@selector(handleSingleTap) forControlEvents:UIControlEventTouchDown];

        [self addSubview:btnSpeak];
        
//        UITapGestureRecognizer *tap =
//        [[UITapGestureRecognizer alloc] initWithTarget:self
//                                                action:@selector(handleSingleTap:)];
//        [self addGestureRecognizer:tap];
        
//        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
//        [btnSpeak addGestureRecognizer:longPressGesture];
    }
    
    return self;
}

- (void)touchUp
{
    NSLog(@"Touch up inside");
    [btnSpeak setTitle:@"Hold to talk" forState:UIControlStateNormal];
}

- (void)handleSingleTap
{
//    CGPoint location = [recognizer locationInView:recognizer.view];
    
    [btnSpeak setTitle:@"Release to stop" forState:UIControlStateNormal];
    
    if (!self.isStarted)
    {
        [self.timer invalidate];
        NSTimer *repeatingTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animateCircle) userInfo:nil repeats:YES];
        self.timer = repeatingTimer;
        
        self.isStarted = YES;        
        [[NSNotificationCenter defaultCenter] postNotificationName:kRecordingStartNotif object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kRecordingEndNotif object:nil];
        
        [self.timer invalidate];
        self.timer = nil;

        self.isStarted = NO;
    }
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

- (void)drawInnerCircle
{
    CAShapeLayer *innerCircle = [[CAShapeLayer alloc] init];
    innerCircle.fillColor = kInnerCircleBgColor.CGColor;
    innerCircle.strokeColor = [UIColor clearColor].CGColor;
    innerCircle.lineWidth = 1;
    innerCircle.path = [self makeCircleAtLocation:self.circleCenter radius:self.circleRadius].CGPath;
    innerCircle.opacity = 0.7;
//    innerCircle.position = self.circleCenter;
    
    innerCircle.frame = CGRectMake(self.circleCenter.x - self.circleRadius, self.circleCenter.y - self.circleRadius, self.circleRadius * 2, self.circleRadius * 2);

    [self.layer addSublayer:innerCircle];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
//    rotationAnimation.fromValue = [innerCircle valueForKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 5.0;
    rotationAnimation.repeatCount = FLT_MAX;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];    
    [innerCircle addAnimation:rotationAnimation forKey:@"rotationAnimation"];


    NSLog(@"innerCircle.bounds.size.x = %f, innerCircle.bounds.size.y= %f", innerCircle.frame.origin.x, innerCircle.frame.origin.y);

    NSLog(@"innerCircle.anchorPoint.x = %f, innerCircle.anchorPoint.y= %f", innerCircle.position.x, innerCircle.position.y);

    
//    CATransform3D rotationTransform = CATransform3DMakeRotation(1.0f * M_PI, 0, 0, 1.0);
//    
//    CABasicAnimation* rotationAnimation;
//    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
//    
//    rotationAnimation.toValue = [NSValue valueWithCATransform3D:rotationTransform];
//    rotationAnimation.duration = 3.0f;
//    rotationAnimation.cumulative = YES;
//    rotationAnimation.repeatCount = FLT_MAX;
//    
//    [innerCircle addAnimation:rotationAnimation forKey:@"rotationAnimation"];

}

- (void)drawCircleWithRadius:(CGFloat)radius
{
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
    
    [pathAnimation setDuration:0.05];
    [pathAnimation setRepeatCount:1.0f];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
 
    circleOne.path = [self makeArcWithradius:self.circleRadius startRadian:0.0f endRadian:60.0f clockwise:YES].CGPath;
    [circleOne addAnimation:pathAnimation forKey:@"changePathAnimation"];
    
//    circleOne.anchorPoint = CGPointMake(1.0f, 0.5f);
//    circleOne.affineTransform = CGAffineTransformMakeRotation((CGFloat)M_PI / 3);    
        
    NSLog(@"circleOne.anchorPoint.x = %f, circleOne.anchorPoint.y =  %f", circleOne.anchorPoint.x, circleOne.anchorPoint.y);
    
//    circleTwo.path = [self makeArcWithradius:self.circleRadius startRadian:120.0f endRadian:180.0f clockwise:YES].CGPath;
//    [circleTwo addAnimation:pathAnimation forKey:@"changePathAnimation"];    
//    
//    circleThree.path = [self makeArcWithradius:self.circleRadius startRadian:-60.0f endRadian:-120.0f clockwise:NO].CGPath;
//    [circleThree addAnimation:pathAnimation forKey:@"changePathAnimation"];
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
    } else {
        self.circleRadius -= 1;
    }    
    
    [self drawCircleWithRadius:circleRadius];
}

- (void)drawImage:(CGRect)frame
{
    CGRect rect = CGRectMake(CGRectGetMidX(frame) - 40, CGRectGetMidY(frame) -40, 80, 80);
    UIGraphicsBeginImageContext(rect.size);
    UIImage *image = [UIImage imageNamed:@"speak.jpg"];
    [image drawInRect:rect];
    UIGraphicsEndImageContext();
    
    UIImageView *ivSpeak = [[UIImageView alloc] initWithFrame:rect];
    ivSpeak.image = image;
    
    [self addSubview:ivSpeak];
}

- (void)showText:(CGRect)frame withString:(NSString *)text
{
    CGRect rect = CGRectMake(CGRectGetMidX(frame) - 20, CGRectGetMidY(frame) -20, 40, 40);
    
   label = [[TTTAttributedLabel alloc] initWithFrame:rect];
    [label setBackgroundColor:kInnerCircleBgColor];
//    label.font = [UIFont systemFontOfSize:18];r
    label.textColor = [UIColor whiteColor];
    label.numberOfLines = 0;
    
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^ NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:16];
        CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        if (font) {
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)font range:NSMakeRange(0, text.length)];
            CFRelease(font);
        }
        
        return mutableAttributedString;
    }];
    
    [self addSubview:label];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}

@end
