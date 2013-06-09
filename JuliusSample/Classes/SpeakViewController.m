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

int circleRadius = 80;
int changeCount = 0;

@synthesize circle = _circle;

- (void)initCircle
{
    // Set up the shape of the circle
    _circle = [CAShapeLayer layer];

    // Configure the apperence of the circle
    self.circle.fillColor = [UIColor clearColor].CGColor;
    self.circle.strokeColor = [UIColor grayColor].CGColor;
    self.circle.lineWidth = 2;
    
    // Add to parent layer
    [self.view.layer addSublayer:self.circle];
    
    [self drawCircleWithRadius:circleRadius];
    
    }

- (void)drawCircleWithRadius:(CGFloat)radius
{
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue   = [NSNumber numberWithFloat:1.0f];

    [pathAnimation setDuration:0.1];
    [pathAnimation setRepeatCount:1.0f];
    [pathAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    self.circle.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 2.0*radius, 2.0*radius) cornerRadius:radius].CGPath;
    
    // Center the shape in self.view
    self.circle.position = CGPointMake(CGRectGetMidX(self.view.frame) - radius, CGRectGetMidY(self.view.frame) - radius);
//    self.circle.anchorPoint = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);


    NSLog(@"x = %f", CGRectGetMidX(self.view.frame) - radius);
    NSLog(@"y = %f", CGRectGetMidY(self.view.frame) - radius);
    
    [self.circle addAnimation:pathAnimation forKey:@"changePathAnimation"];
}

- (void)animateImageView {
    if (changeCount < 20)
    {
        changeCount++;
        circleRadius += 1.0f;
    } else if (changeCount > 20){
        circleRadius -= 1.0f;
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
@end
