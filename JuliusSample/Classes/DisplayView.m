//
//  DisplayView.m
//  PitchDetector
//
//  Created by OwenWu on 15/05/2013.
//
//

#import "DisplayView.h"
#import <QuartzCore/QuartzCore.h>

@implementation DisplayView {

    float stepX;//
    int dynLinNum;// Dynamic Line Number

    CGContextRef context;// Drawing Context
    
    NSMutableArray *bndsLocation; // Word Boundary Locations in Float
    NSMutableArray *rmsAverageAry;// RMS Average for each word
    NSMutableArray *pitchAvgAry;  // Pitch Average for each word
}

@synthesize lineArray, pitchLineArray, boundsArray, textArray;

#define kLines 50 // initial line number

-(float)calculateAverageOfAry:(NSArray*)temp fromIdx:(NSInteger)strPt toIdx:(NSInteger)endPt
{
    float avgFloat = 0;
    
    for (int i=strPt; i<endPt; i++) {
        avgFloat += [[temp objectAtIndex:i] floatValue];
    }
    NSLog(@"222 %f",avgFloat);
    
    avgFloat = avgFloat/(endPt-strPt);
    return avgFloat;
}

-(void)handleSwipeRight
{
    [self removeFromSuperview];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBackToRecordingInterface object:nil];
}

- (void)drawSomething{
	// Cells spawn in the bottom, moving up
	CAEmitterLayer *fireworksEmitter = [CAEmitterLayer layer];
	CGRect viewBounds = self.layer.bounds;
	fireworksEmitter.emitterPosition = CGPointMake(viewBounds.size.width/2.0, viewBounds.size.height);
	fireworksEmitter.emitterSize	= CGSizeMake(viewBounds.size.width/2.0, 0.0);
	fireworksEmitter.emitterMode	= kCAEmitterLayerOutline;
	fireworksEmitter.emitterShape	= kCAEmitterLayerLine;
	fireworksEmitter.renderMode		= kCAEmitterLayerAdditive;
	fireworksEmitter.seed = (arc4random()%100)+1;
	
	// Create the rocket
	CAEmitterCell* rocket = [CAEmitterCell emitterCell];
	
	rocket.birthRate		= 1.0;
	rocket.emissionRange	= 0.25 * M_PI;  // some variation in angle
	rocket.velocity			= 380;
	rocket.velocityRange	= 100;
	rocket.yAcceleration	= 75;
	rocket.lifetime			= 1.02;	// we cannot set the birthrate < 1.0 for the burst
	
	rocket.contents			= (id) [[UIImage imageNamed:@"DazRing"] CGImage];
	rocket.scale			= 0.2;
	rocket.color			= [[UIColor redColor] CGColor];
	rocket.greenRange		= 1.0;		// different colors
	rocket.redRange			= 1.0;
	rocket.blueRange		= 1.0;
	rocket.spinRange		= M_PI;		// slow spin
	
    
	
	// the burst object cannot be seen, but will spawn the sparks
	// we change the color here, since the sparks inherit its value
	CAEmitterCell* burst = [CAEmitterCell emitterCell];
	
	burst.birthRate			= 1.0;		// at the end of travel
	burst.velocity			= 0;
	burst.scale				= 2.5;
	burst.redSpeed			=-1.5;		// shifting
	burst.blueSpeed			=+1.5;		// shifting
	burst.greenSpeed		=+1.0;		// shifting
	burst.lifetime			= 0.35;
	
	// and finally, the sparks
	CAEmitterCell* spark = [CAEmitterCell emitterCell];
	
	spark.birthRate			= 400;
	spark.velocity			= 125;
	spark.emissionRange		= 2* M_PI;	// 360 deg
	spark.yAcceleration		= 75;		// gravity
	spark.lifetime			= 3;
    
	spark.contents			= (id) [[UIImage imageNamed:@"DazStarOutline"] CGImage];
	spark.scaleSpeed		=-0.2;
	spark.greenSpeed		=-0.1;
	spark.redSpeed			= 0.4;
	spark.blueSpeed			=-0.1;
	spark.alphaSpeed		=-0.25;
	spark.spin				= 2* M_PI;
	spark.spinRange			= 2* M_PI;
	
	// putting it together
	fireworksEmitter.emitterCells	= [NSArray arrayWithObject:rocket];
	rocket.emitterCells				= [NSArray arrayWithObject:burst];
	burst.emitterCells				= [NSArray arrayWithObject:spark];
	[self.layer addSublayer:fireworksEmitter];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor =  [UIColor colorWithRed:92/255.0 green:183/255.0 blue:236/255.0 alpha:1.0];
        
        lineArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        pitchLineArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        boundsArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        
        dynLinNum = kLines;
        stepX = self.frame.size.width / kLines;
        
        bndsLocation = [[NSMutableArray alloc] initWithCapacity:kLines];
        rmsAverageAry = [[NSMutableArray alloc] initWithCapacity:kLines];
        
        //temporarily populate the array with random data
//        for (int aloop = 0; aloop < kLines; aloop++) {
//            int rand = arc4random()%100;
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight)];
        [self addGestureRecognizer:swipeRight];
        
        [self drawSomething];
    }
    return self;
}

-(void) initTextLayers
{
    self.clipsToBounds = YES;
    
    CGRect viewBounds = self.bounds;
    CGContextTranslateCTM(context, 0, viewBounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextSetRGBFillColor(context, 0.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 2.0);
    CGContextSelectFont(context, "Helvetica", 20.0, kCGEncodingMacRoman);
    CGContextSetCharacterSpacing(context, 1.7);
    CGContextSetTextDrawingMode(context, kCGTextFill);

    if ([textArray count] == 0 || [bndsLocation count] == 0) return;
    
    for (int i = 0; i < [textArray count]; i++) {
        NSString *oneWord = [textArray objectAtIndex:i];
        CGFloat xValue = [[bndsLocation objectAtIndex:i] floatValue];
        
        // DO NOT DISPLAY SILENCE
        // DISPLAY ONLY WORDS
        if ([oneWord isEqualToString:@"<s>"] || [oneWord isEqualToString:@"</s>"]) continue;
        else CGContextShowTextAtPoint(context, xValue, 125.0, [oneWord cStringUsingEncoding:NSUTF8StringEncoding], [oneWord length]);
    }
}

// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing starts
    context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    
    // Clean up the screen and init the line array if line goes outside the screen
    if ([lineArray count] > dynLinNum) {
        NSLog(@"Goes outside of %d points! Will Double!!", dynLinNum);
        dynLinNum = dynLinNum * 2;
        stepX = self.frame.size.width / dynLinNum;
    }
    
    // ---------------------------------
    // Draw the line array for Pitch
    int index = 0;
    float previousY = 0.0;
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    NSArray *tempPitch = [NSArray arrayWithArray:pitchLineArray];
    for (NSNumber *aNumber in tempPitch) {
        
        if (index > 0) {
            CGContextMoveToPoint(context, (index-1) * stepX, previousY);
            CGContextAddLineToPoint(context, index * stepX, [aNumber floatValue]);
            CGContextStrokePath(context);
        }
        previousY = [aNumber floatValue];
        index++;
    }

    // ---------------------------------
    // Draw the points as boundaries
    int sumOfDuration = 0;
    for (NSNumber *duration in boundsArray) {
        sumOfDuration += [duration intValue];
    }
    
    float percentage, xIndex = 0.0;
    if ([tempPitch count] != 0) {
        previousY = [[tempPitch objectAtIndex:0] floatValue];
//        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
//        NSLog(@"333/%u:%f", [boundsArray count], previousY);
        for (NSNumber *dur in boundsArray) {
            percentage = [dur floatValue] / sumOfDuration;
            xIndex += percentage * [pitchLineArray count];
            [bndsLocation addObject:[NSNumber numberWithFloat:xIndex*stepX]];
            //Draw the vertical lines
//            NSLog(@"444/%u:%f", [bndsLocation count], previousY);
        }
    }
    
    // ---------------------------------
    // Draw the line array for RMS/Gain
    index = 0; previousY = 0.0;
    CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
    NSArray *tempRMS = [NSArray arrayWithArray:lineArray];
    for (NSNumber *someNumber in tempRMS) {
        if (index > 0) {
            CGContextMoveToPoint(context, (index-1) * stepX, previousY);
            CGContextAddLineToPoint(context, index * stepX, [someNumber floatValue]);
            CGContextStrokePath(context);
        }
        previousY = [someNumber floatValue];
        index++;
        
        for (int bndIdx = 0; bndIdx < [bndsLocation count]; bndIdx++) {
//            NSLog(@"%f:%u:%f", xIndex*stepX, [bndsLocation count], [[bndsLocation objectAtIndex:bndIdx] floatValue]);
            if (index*stepX == [[bndsLocation objectAtIndex:bndIdx] floatValue]) {
                [rmsAverageAry addObject:[NSNumber numberWithFloat:[self calculateAverageOfAry:tempRMS fromIdx:[bndsLocation[bndIdx-1] intValue] toIdx:index]]];
//                NSLog(@"111 %d/\n%@", [rmsAverageAry count], [rmsAverageAry description]);
            }
        }
    }
    
    [self initTextLayers];
}

-(void)cleanUpContext
{
    if (!context) {
        context = UIGraphicsGetCurrentContext();
    }
    CGContextClearRect(context,self.frame);
    
    [lineArray removeAllObjects];
    [pitchLineArray removeAllObjects];
    [boundsArray removeAllObjects];
    [bndsLocation removeAllObjects];
    [textArray removeAllObjects];

    dynLinNum = kLines;
}

@end