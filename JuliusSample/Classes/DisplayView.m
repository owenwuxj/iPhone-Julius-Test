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

    float stepX, xIndex;//
    int dynLinNum;// Dynamic Line Number

    CGContextRef context;// Drawing Context
    
    NSMutableArray *bndsLocation; // Word Boundary Locations in Float
    NSMutableArray *rmsAverageAry;// RMS Average for each word
    NSMutableArray *pitchAvgAry;  // Pitch Average for each word
}

@synthesize lineArray, pitchLineArray, boundsArray, textArray;

#define kLines 50 // initial line number
#define kLetterWidth 20 // letter width unit
#define kLetterHeight 16.0
#define kLetterPositionY 100.0

#pragma mark -
#pragma mark Private methods

-(float)calculateAverageOfAry:(NSArray*)temp fromIdx:(NSInteger)strPt toIdx:(NSInteger)endPt
{
    float avgFloat = 0;
    
    for (int i=strPt; i<endPt; i++) {
        avgFloat += [[temp objectAtIndex:i] floatValue];
    }
//    NSLog(@"222 %f",avgFloat);
    
    avgFloat = avgFloat/(endPt-strPt);
    return avgFloat;
}

-(void)handleSwipeRight
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kBackToRecordingInterface object:nil];
}

-(void)initBoundsLocationWithPoints:(NSInteger)checker {
    int sumOfDuration = 0;
    for (NSNumber *duration in boundsArray) {
        sumOfDuration += [duration intValue];
    }
    
    // ---------------------------------
    //Draw the vertical lines
    float percentage = 0.0;
    if (checker != 0) {
        for (NSNumber *dur in boundsArray) {
            percentage = [dur floatValue] / sumOfDuration;
            xIndex += percentage * [pitchLineArray count];
            [bndsLocation addObject:[NSNumber numberWithFloat:xIndex*stepX]];
//            NSLog(@"444/%u", [bndsLocation count]);
        }
    }
}

/*
- (void)animateFireworks{
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
    
	spark.contents			= (id) [[UIImage imageNamed:@"DazRing"] CGImage];
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

-(void)drawTextContent
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
    
    if ([textArray count] <= 2 || [bndsLocation count] <= 1) return;// Deal with <s></s>
    
    for (int i = 1; i < [textArray count]; i++) {// Display words skipping <s> (the first silence)
        NSString *oneWord = [textArray objectAtIndex:i];
        CGFloat xValue = [[bndsLocation objectAtIndex:i] floatValue];
        
        // DO NOT DISPLAY SILENCE
        // DISPLAY ONLY WORDS
        if ([oneWord isEqualToString:@"<s>"] || [oneWord isEqualToString:@"</s>"]) continue;
        else CGContextShowTextAtPoint(context, xValue, 125.0, [oneWord cStringUsingEncoding:NSUTF8StringEncoding], [oneWord length]);
    }
}
*/

-(void)addTextLabelsToView
{
    [self initBoundsLocationWithPoints:1];//just don't pass 0

    if ([textArray count] <= 2 || [bndsLocation count] <= 1) return;
    
    for (int i = 1; i < [textArray count]; i++) {
        NSString *oneWord = [textArray objectAtIndex:i];

        CGFloat xValue = 0.0;
        for (int j=i-1; j>0; j--) {
            xValue += [[textArray objectAtIndex:j] length] * kLetterWidth;
        }
        
        UILabel *aLabel = [[UILabel alloc] initWithFrame:CGRectMake(xValue, kLetterPositionY, [oneWord length] * kLetterWidth, kLetterHeight)];

        if (i == 1) {
            aLabel.font = [UIFont systemFontOfSize:14.0+5];
            aLabel.frame = CGRectMake(aLabel.frame.origin.x, aLabel.frame.origin.y-5, aLabel.frame.size.width, aLabel.frame.size.height);
        }
        
        if (i == 3) {// change the background color on the 3rd word
            aLabel.backgroundColor = [UIColor blueColor];
        }

        if ([oneWord isEqualToString:@"<s>"] || [oneWord isEqualToString:@"</s>"]) continue;// DO NOT DISPLAY SILENCE
        else aLabel.text = oneWord;// DISPLAY ONLY WORDS
        
        [self addSubview:aLabel];
    }
}

-(NSInteger)drawPitchLine {
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
    return [tempPitch count];
}

//-(void)doSomething{
//    NSLog(@"%f:%u:%f", xIndex*stepX, [bndsLocation count], [[bndsLocation objectAtIndex:0] floatValue]);
//    for (int bndIdx = 0; bndIdx < [bndsLocation count]; bndIdx++) {
//        //            NSLog(@"%f:%u:%f", xIndex*stepX, [bndsLocation count], [[bndsLocation objectAtIndex:bndIdx] floatValue]);
//        if (index*stepX == [[bndsLocation objectAtIndex:bndIdx] floatValue])
//            [rmsAverageAry addObject:[NSNumber numberWithFloat:[self calculateAverageOfAry:tempRMS fromIdx:[bndsLocation[bndIdx-1] intValue] toIdx:index]]];
//    }
//}
//
-(void)drawGainLine {
    int index = 0;
    int previousY = 0.0;
    
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
    }
}

#pragma mark -
#pragma mark UIResponder Inherited methods

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self handleSwipeRight];
}

#pragma mark -
#pragma mark UIView Inherited methods

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        
        lineArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        pitchLineArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        boundsArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        
        dynLinNum = kLines;
        stepX = self.frame.size.width / kLines;
        
        bndsLocation = [[NSMutableArray alloc] initWithCapacity:kLines];
        rmsAverageAry = [[NSMutableArray alloc] initWithCapacity:kLines];
        
//        UITapGestureRecognizer *tapView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight)];
//        [self addGestureRecognizer:tapView];
//        [self animateFireworks];
    }
    return self;
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
    NSInteger pitchCnt = [self drawPitchLine];

    // ---------------------------------
    // Draw the points as boundaries/Get the points of duration
//    [self initBoundsLocationWithPoints:pitchCnt];
    
    // ---------------------------------
    // Draw the line array for RMS/Gain
    [self drawGainLine];
    
//    [self drawTextContent];
//    [self addTextLabelsToView];
}

#pragma mark -
#pragma mark Public methods

-(void)cleanUpContext
{
    // Clear the whole context
    if (!context) {
        context = UIGraphicsGetCurrentContext();
    }
    CGContextClearRect(context,self.frame);
    
    // Clear all the arrays
    [lineArray removeAllObjects];
    [pitchLineArray removeAllObjects];
    [boundsArray removeAllObjects];
    [bndsLocation removeAllObjects];
    [textArray removeAllObjects];

    // Clear all the UILabels
    for (id oneView in self.subviews) {
        if ([oneView isKindOfClass:[UILabel class]]) {
            [oneView removeFromSuperview];
        }
    }
    
    dynLinNum = kLines;
}

@end