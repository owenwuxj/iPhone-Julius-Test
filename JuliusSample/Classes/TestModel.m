//
//  TestModel.m
//  JuliusSample
//
//  Created by Matthew Magee on 12/08/2013.
//
//

#import "TestModel.h"

@implementation TestModel

- (NSString*)dumpYourLoadIntoAString {
    
    NSString *returnString = @"Dumping load...\n\n\n\n";
    
    if (self.arrayOfPitchValues) {
        returnString = [returnString stringByAppendingString:[NSString stringWithFormat:@"There are %d pitch values.\n\n",[self.arrayOfPitchValues count]]];
        for (NSNumber *someNumber in self.arrayOfPitchValues) {
            
            returnString = [returnString stringByAppendingString:[NSString stringWithFormat:@"\n\nPitch: %f",[someNumber floatValue]]];
            
        }
    }
    else if (self.arrayOfWords) {
        
    }
    else {
        
        returnString = @"No load to dump!";
        
    }
    
    return returnString;
    
}

@end
