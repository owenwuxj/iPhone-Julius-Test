//
//  TestView.h
//  JuliusSample
//
//  Created by Matthew Magee on 12/08/2013.
//
//

#import <UIKit/UIKit.h>

@protocol TestViewUIDelegate <NSObject>

- (void)userRequestsRecordingStart;
- (void)userRequestsRecordingEnd;

@end

@interface TestView : UIView

@property (nonatomic) id<TestViewUIDelegate> delegate;

- (void)configureViewReadyToRecord;
- (void)configureViewForCalculatingResults;
- (void)configureViewForShowingResults:(NSString*)pResultsString;

@end
