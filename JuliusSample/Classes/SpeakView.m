//
//  SpeakView.m
//  JuliusSample
//
//  Created by Michael Wang on 13-6-13.
//
//

#import "SpeakView.h"

#define kCircleRadius 40

@implementation SpeakView

@synthesize circle = _circle,
            circleCenter,
            circleRadius,
            scaleUp;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initCircle:frame];
        [self setBackgroundColor:[UIColor colorWithRed:92/255.0 green:183/255.0 blue:236/255.0 alpha:1.0]];
        
        UITapGestureRecognizer *tap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
}

- (void)handleSingleTap:(UIGestureRecognizer *)recognizer
{
    [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animateCircle) userInfo:nil repeats:YES];

}

- (void)initCircle:(CGRect)frame
{
    self.circleCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
    self.circleRadius = kCircleRadius;
    
    // Set up the shape of the circle
    _circle = [CAShapeLayer layer];
    
    // Configure the apperence of the circle
    self.circle.fillColor = [UIColor colorWithRed:198/255.0 green:236/255.0 blue:252/255.0 alpha:1.0].CGColor;
    self.circle.strokeColor = [UIColor colorWithRed:198/255.0 green:236/255.0 blue:252/255.0 alpha:1.0].CGColor;
    self.circle.lineWidth = 5;
    
    // Add to parent layer
    [self.layer addSublayer:self.circle];
    
    [self drawInnerCircle];
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

- (void)drawInnerCircle
{
    CAShapeLayer *innerCircle = [[CAShapeLayer alloc] init];
    innerCircle.fillColor = [UIColor colorWithRed:51/255.0 green:144/255.0 blue:211/255.0 alpha:1.0].CGColor;
    innerCircle.strokeColor = [UIColor clearColor].CGColor;
    innerCircle.lineWidth = 1;
    innerCircle.path = [self makeCircleAtLocation:self.circleCenter radius:self.circleRadius].CGPath;
    
    [self.layer addSublayer:innerCircle];
}

- (void)drawCircleWithRadius:(CGFloat)radius
{
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue   = [NSNumber numberWithFloat:1.0f];
    
    [pathAnimation setDuration:0.05];
    [pathAnimation setRepeatCount:1.0f];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    UIBezierPath *path = [self makeCircleAtLocation:self.circleCenter radius:self.circleRadius];
    self.circle.path = path.CGPath;
    
    [self.circle addAnimation:pathAnimation forKey:@"changePathAnimation"];
}

- (void)animateCircle
{
    if (self.circleRadius == 40){
        self.scaleUp = YES;
    } else if (self.circleRadius == 80){
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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
