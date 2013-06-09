//
//  SpeakViewController.m
//  JuliusSample
//
//  Created by Michael Wang on 13-6-8.
//
//

#import "SpeakViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface SpeakViewController ()
@property (nonatomic, strong) CAShapeLayer *circle;
@end 

@implementation SpeakViewController

int circleRadius = 1;
int changeCount = 0;
BOOL scaleUp = NO;

@synthesize circle = _circle,
            circleRadius,
            circleCenter;

- (void)initCircle
{
    // Set up the shape of the circle
    _circle = [CAShapeLayer layer];

    // Configure the apperence of the circle
    self.circle.fillColor = [UIColor clearColor].CGColor;
    self.circle.strokeColor = [UIColor grayColor].CGColor;
    self.circle.lineWidth = 1;
    
    // Create a circle with 1-point width/height.
//    self.circle.path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, 1, 1)].CGPath;
    
    CGPoint point = CGPointMake(100, 100);
    UIBezierPath *path = [self makeCircleAtLocation:point radius:30];
    self.circle.path = path.CGPath;
    
    // Use the layer transform to scale the circle up to the size of the view.
//    [self.circle setValue:@(1) forKeyPath:@"transform.scale"];
    
//    self.circle.position = CGPointMake(CGRectGetMidX(self.view.frame) - 60, CGRectGetMidY(self.view.frame) - 100);
    
    // Add to parent layer
    [self.view.layer addSublayer:self.circle];
    
//    [self drawCircleWithRadius2:circleRadius];
}

- (UIBezierPath *)makeCircleAtLocation:(CGPoint)location radius:(CGFloat)radius
{
    self.circleCenter = location;
    self.circleRadius = radius;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path addArcWithCenter:self.circleCenter
                    radius:self.circleRadius
                startAngle:0.0
                  endAngle:M_PI * 2.0
                 clockwise:YES];
    
    return path;
}

- (void)drawCircleWithRadius:(CGFloat)radius
{
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue   = [NSNumber numberWithFloat:1.0f];

    [pathAnimation setDuration:0.1];
    [pathAnimation setRepeatCount:1.0f];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
//    self.circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    
    // Center the shape in self.view
//    self.circle.position = CGPointMake(CGRectGetMidX(self.view.frame) - radius, CGRectGetMidY(self.view.frame) - radius);
//    self.circle.anchorPoint = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    
    CGPoint point = CGPointMake(100, 100);
    UIBezierPath *path = [self makeCircleAtLocation:point radius:circleRadius];
    self.circle.path = path.CGPath;
    
    NSLog(@"circle.x = %f, circle.y= %f, size.width = %f, size.height=%f", self.circle.frame.origin.x, self.circle.frame.origin.y, self.circle.frame.size.width, self.circle.frame.size.height);

    NSLog(@"x = %f", CGRectGetMidX(self.view.frame) - radius);
    NSLog(@"y = %f", CGRectGetMidY(self.view.frame) - radius);
    
    [self.circle addAnimation:pathAnimation forKey:@"changePathAnimation"];
}

- (void)drawCircleWithRadius2:(CGFloat)radius
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = [self.circle valueForKeyPath:@"transform.scale"];
    animation.toValue = [NSNumber numberWithFloat:radius];
    animation.duration = 3.0;
    animation.timingFunction = [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseOut];
    
    // Important: change the actual layer property before installing the animation.
    [self.circle setValue:animation.toValue forKeyPath:animation.keyPath];
    
    // Now install the explicit animation, overriding the implicit animation.
    [self.circle addAnimation:animation forKey:animation.keyPath];
}

- (void)animateImageView
{
    if (circleRadius == 1){
        scaleUp = YES;
    } else if (circleRadius == 100){
        scaleUp = NO;
    }
    
    if (scaleUp)
    {
        circleRadius += 1;
    } else {
        circleRadius -= 1;
    }    
    
    [self drawCircleWithRadius:circleRadius];
}

- (void)setup
{
    [self initCircle];

    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(animateImageView) userInfo:nil repeats:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    UIGraphicsBeginImageContext(CGSizeMake(100, 100));
    UIImage *image = [UIImage imageNamed:@"speak.jpg"];
    //    [image drawAtPoint:CGPointMake(110, 224)];
    [image drawInRect:CGRectMake(0, 0, 2.0*circleRadius, 2.0*circleRadius)];
    UIGraphicsEndImageContext();
}

- (void)dealloc
{
    [super dealloc];
    [self.circle release];
}
@end
