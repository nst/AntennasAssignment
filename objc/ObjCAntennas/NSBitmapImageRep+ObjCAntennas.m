//
//  NSBitmapImageRep+ObjCAntennas.m
//  ObjCAntennas
//
//  Created by Nicolas Seriot on 10/07/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import "NSBitmapImageRep+ObjCAntennas.h"

@implementation NSBitmapImageRep (ObjCAntennas)

- (double)intensityAtPoint:(NSPoint)point {
#if 1
    unsigned char * bitmapData = [self bitmapData];

    NSUInteger index = (NSUInteger)(point.y*self.size.width*4 + point.x*4);
    
    unsigned char value = bitmapData[index];
    
    return (255.0 - value) / 255.0;
#else
    NSUInteger pixel[3];

    [self getPixel:pixel atX:point.x y:point.y];

    return (255.0 - pixel[0]) / 255.0;
#endif
}

- (DoubleMatrix *)doubleMatrix {
    DoubleMatrix *m = [[DoubleMatrix alloc] initWithColumns:self.size.width rows:self.size.height];
    
    for(NSUInteger x = 0; x < self.size.width; x++) {
        for(NSUInteger y = 0; y < self.size.height; y++) {
            NSPoint p = NSMakePoint(x, y);
            double intensity = [self intensityAtPoint:p];
            [m setValue:intensity atPoint:p];
        }
    }
    
    return m;
}

- (void)updateWithDoubleMatrix:(DoubleMatrix *)m {

    assert(m.numberOfColumns == self.size.width);
    assert(m.numberOfRows == self.size.height);
    
    __block double maxValue = [m highestValue];
    
    for(NSUInteger x = 0; x < self.size.width; x++) {
        for(NSUInteger y = 0; y < self.size.height; y++) {

            NSPoint p = NSMakePoint(x, y);
            double value = [m valueAtPoint:p];
            double pixelValue = value * 255.0 / maxValue;
            
            NSUInteger pixel[4] = {(NSUInteger)pixelValue, (NSUInteger)pixelValue, (NSUInteger)pixelValue, 255};
            
            [self setPixel:pixel atX:x y:y];
        }
    }
}

@end
