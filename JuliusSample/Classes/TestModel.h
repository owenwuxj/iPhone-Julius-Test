//
//  TestModel.h
//  JuliusSample
//
//  Created by Matthew Magee on 12/08/2013.
//
//

#import <Foundation/Foundation.h>

@interface TestModel : NSObject

@property (nonatomic) NSMutableArray *arrayOfPitchValues;

- (NSString*)dumpYourLoadIntoAString;

@end
