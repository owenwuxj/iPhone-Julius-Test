//
//  SpeakView.m
//  JuliusSample
//
//  Created by Michael Wang on 13-6-13.
//
//

#import "SpeakView.h"

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
        
        [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(animateCircle) userInfo:nil repeats:YES];

    }
    
    return self;
}

- (void)initCircle:(CGRect)frame
{
    self.circleCenter = CGPointMake(frame.size.width/2, frame.size.height/2);
    self.circleRadius = 40;
    
    // Set up the shape of the circle
    _circle = [CAShapeLayer layer];
    
    // Configure the apperence of the circle
    self.circle.fillColor = [UIColor clearColor].CGColor;
    self.circle.strokeColor = [UIColor grayColor].CGColor;
    self.circle.lineWidth = 3;
    
    // Add to parent layer
    [self.layer addSublayer:self.circle];
    
    [self drawGrayCircle];
}

- (UIBezierPath *)makeCircleAtLocation:(CGPoint)location radius:(CGFloat)radius
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:location
                    radius:radius
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    
    return path;
}

- (void)drawGrayCircle
{
    CAShapeLayer *redCircle = [[CAShapeLayer alloc] init];
    redCircle.fillColor = [UIColor lightGrayColor].CGColor;
    redCircle.strokeColor = [UIColor clearColor].CGColor;
    redCircle.lineWidth = 1;
    
    redCircle.path = [self makeCircleAtLocation:self.circleCenter radius:self.circleRadius].CGPath;
    [self.layer addSublayer:redCircle];
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
    } else if (self.circleRadius == 100){
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
