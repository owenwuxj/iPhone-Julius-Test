//
//  DisplayView.h
//  PitchDetector
//
//  Created by OwenWu on 15/05/2013.
//
//

#import <UIKit/UIKit.h>

@interface DisplayView : UIView

@property(nonatomic, retain) NSMutableArray *lineArray;
@property(nonatomic, retain) NSMutableArray *pitchLineArray;
@property(nonatomic, retain) NSMutableArray *boundsArray;

-(void)cleanUpContext;

@end
