//
//  DisplayView.h
//  PitchDetector
//
//  Created by OwenWu on 15/05/2013.
//
//

#import <UIKit/UIKit.h>

@interface DisplayView : UIView

@property(nonatomic, strong) NSMutableArray *lineArray;
@property(nonatomic, strong) NSMutableArray *pitchLineArray;
@property(nonatomic, strong) NSMutableArray *boundsArray;
@property(nonatomic, strong) NSMutableArray *textArray;

-(void)cleanUpContext;

@end