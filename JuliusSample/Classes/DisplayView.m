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

    float stepX;
    CGContextRef context;
    NSMutableArray *bndsLocation;
    NSMutableArray *rmsAverageAry;
}

@synthesize lineArray, pitchLineArray, boundsArray, textArray;

#define kLines 50

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor blackColor];
        
        lineArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        pitchLineArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        boundsArray = [[NSMutableArray alloc] initWithCapacity:kLines];
        
        stepX = self.frame.size.width / kLines;
        bndsLocation = [[NSMutableArray alloc] initWithCapacity:kLines];
        rmsAverageAry = [[NSMutableArray alloc] initWithCapacity:kLines];
        
        //temporarily populate the array with random data
//        for (int aloop = 0; aloop < kLines; aloop++) {
//            int rand = arc4random()%100;
    }
    return self;
}

-(void) initTextLayers
{
    self.clipsToBounds = YES;
//    self.userInteractionEnabled = YES;
//    self.layer.cornerRadius = center.x;
//    self.layer.borderWidth = 1.0;
//    self.layer.borderColor = [[UIColor grayColor] CGColor];
//    
//    self.layer.shadowColor = UIColor.blackColor.CGColor;
//    self.layer.shadowRadius = 2;
//    self.layer.shadowOpacity = 0.6;
//    self.layer.shadowOffset = CGSizeMake(0, 1);
    
    CGRect viewBounds = self.bounds;
    CGContextTranslateCTM(context, 0, viewBounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    CGContextSetRGBFillColor(context, 0.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 2.0);
    CGContextSelectFont(context, "Helvetica", 20.0, kCGEncodingMacRoman);
    CGContextSetCharacterSpacing(context, 1.7);
    CGContextSetTextDrawingMode(context, kCGTextFill);

    if ([textArray count] == 0) return;
    
    for (int i = 0; i < [textArray count]; i++) {
        NSString *oneWord = [textArray objectAtIndex:i];
        CGFloat xValue = [[bndsLocation objectAtIndex:i] floatValue];
        NSLog(@"222 %f",xValue);
        
        if ([oneWord isEqualToString:@"<s>"] || [oneWord isEqualToString:@"</s>"]) continue;
        else CGContextShowTextAtPoint(context, xValue, 125.0, [oneWord cStringUsingEncoding:NSUTF8StringEncoding], [oneWord length]);
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing starts
    context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    
    // Clean up the screen and init the line array if line goes outside the screen
    if ([lineArray count] >= kLines) {
//            [self cleanUpContext];
        NSLog(@"Goes outside of %d points!!!", kLines);
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
        
        for (NSNumber *dur in boundsArray) {
            percentage = [dur floatValue] / sumOfDuration;
            xIndex += percentage * [pitchLineArray count];
            [bndsLocation addObject:[NSNumber numberWithFloat:xIndex*stepX]];
            
            NSLog(@"%f/%u:%f", xIndex*stepX, [pitchLineArray count], previousY);
            
            //Draw the vertical lines
//            CGContextFillRect(context, CGRectMake(xIndex*stepX,previousY,3,-100));
//            CGContextAddEllipseInRect(context,CGRectMake(xIndex, previousY, 13.0, 13.0));
//            CGContextDrawPath(context, kCGPathFill);
//            CGContextStrokePath(context);
        }
    }
    
    // ---------------------------------
    // Draw the line array for RMS/Gain
    index = 0;
    previousY = 0.0;
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
    
    [self initTextLayers];
//    NSLog(@"number of pitchLineArray:%d", [pitchLineArray count]);
//    NSLog(@"number of lineArray:%d", [lineArray count]);
}

-(void)dealloc
{
    if (lineArray) {
        [lineArray release];
        lineArray = nil;
    }
    
    if (pitchLineArray) {
        [pitchLineArray release];
        pitchLineArray = nil;
    }
    
    if (boundsArray) {
        [boundsArray release];
        boundsArray = nil;
    }
    
    if (bndsLocation) {
        [bndsLocation release];
        bndsLocation = nil;
    }
    
    [super dealloc];
}

-(void)cleanUpContext
{
    if (!context) {
        context = UIGraphicsGetCurrentContext();
    }
    
//    NSLog(@"%@:%f/%f",context,self.frame.size.width, self.frame.size.height);
    CGContextClearRect(context,self.frame);
    [lineArray removeAllObjects];
    [pitchLineArray removeAllObjects];
    [boundsArray removeAllObjects];
    [bndsLocation removeAllObjects];
    [textArray removeAllObjects];
}

@end
