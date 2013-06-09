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

@synthesize circle = _circle,
            circleCenter,
            circleRadius,
            scaleUp;

- (void)initCircle
{
    self.circleCenter = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    self.circleRadius = 1;
    
    // Set up the shape of the circle
    _circle = [CAShapeLayer layer];

    // Configure the apperence of the circle
    self.circle.fillColor = [UIColor clearColor].CGColor;
    self.circle.strokeColor = [UIColor grayColor].CGColor;
    self.circle.lineWidth = 3;
    
    // Add to parent layer
    [self.view.layer addSublayer:self.circle];
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

- (void)drawCircleWithRadius:(CGFloat)radius
{
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue   = [NSNumber numberWithFloat:1.0f];

    [pathAnimation setDuration:0.1];
    [pathAnimation setRepeatCount:1.0f];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    UIBezierPath *path = [self makeCircleAtLocation:self.circleCenter radius:self.circleRadius];
    self.circle.path = path.CGPath;
    
    [self.circle addAnimation:pathAnimation forKey:@"changePathAnimation"];
}

- (void)animateCircle
{
    if (self.circleRadius == 1){
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

- (void)setup
{
    [self initCircle];

    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(animateCircle) userInfo:nil repeats:YES];
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
