//
//  DisplayView.m
//  PitchDetector
//
//  Created by OwenWu on 15/05/2013.
//
//

#import "DisplayView.h"

@implementation DisplayView {

    float stepX;
    
    CGContextRef context;
}

@synthesize lineArray, pitchLineArray, boundsArray;

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
        
        //temporarily populate the array with random data
//        for (int aloop = 0; aloop < kLines; aloop++) {
//            int rand = arc4random()%100;
//            NSLog(@"%d",rand);
//            [lineArray addObject:[NSNumber numberWithFloat:(float)rand]];
//        }
        
    }
    return self;
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
        [self cleanUpContext];
    }
    
    // ---------------------------------
    // Draw the line array for RMS/Gain
    int index = 0;
    float previousY = 0.0;
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
    
    // ---------------------------------
    // Draw the line array for Pitch
    index = 0;
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
    int sum = 0;
    for (NSNumber *duration in boundsArray) {
        sum += [duration intValue];
//        NSLog(@"dur:%d and sum:%d", [duration intValue],sum);
    }
    
    float percentage, xIndex = 0.0;
    if ([tempPitch count] != 0) {
        previousY = [[tempPitch objectAtIndex:0] floatValue];
        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
        for (NSNumber *dur in boundsArray) {
            percentage = [dur floatValue] / sum;
            xIndex += percentage*[pitchLineArray count];
            NSLog(@"%f/%u:%f", xIndex, [pitchLineArray count], previousY);
            
            CGContextFillRect(context, CGRectMake(xIndex*stepX,previousY,3,-100));
//            CGContextAddEllipseInRect(context,CGRectMake(xIndex, previousY, 13.0, 13.0));
//            CGContextDrawPath(context, kCGPathFill);
//            CGContextStrokePath(context);
        }
    }
    
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
}

@end
