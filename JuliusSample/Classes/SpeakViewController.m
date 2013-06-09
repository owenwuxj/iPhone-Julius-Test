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
    self.circleRadius = 40;
    
    // Set up the shape of the circle
    _circle = [CAShapeLayer layer];

    // Configure the apperence of the circle
    self.circle.fillColor = [UIColor clearColor].CGColor;
    self.circle.strokeColor = [UIColor grayColor].CGColor;
    self.circle.lineWidth = 3;
    
    // Add to parent layer
    [self.view.layer addSublayer:self.circle];
    
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
    [self.view.layer addSublayer:redCircle];
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

- (void)setup
{
    [self initCircle];

    [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(animateCircle) userInfo:nil repeats:YES];
}

- (void)drawImage
{
    CGRect rect = CGRectMake(CGRectGetMidX(self.view.frame) - 40, CGRectGetMidY(self.view.frame) -40, 80, 80);
    UIGraphicsBeginImageContext(rect.size);
    UIImage *image = [UIImage imageNamed:@"speak.jpg"];
    [image drawInRect:rect];
    UIGraphicsEndImageContext();
    
    UIImageView *ivSpeak = [[UIImageView alloc] initWithFrame:rect];
    ivSpeak.image = image;
    
    [self.view addSubview:ivSpeak];
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
}

- (void)dealloc
{
    [super dealloc];
    [self.circle release];
}
@end
