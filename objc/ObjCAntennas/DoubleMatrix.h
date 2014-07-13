//
//  Matrix.h
//  ObjCAntennas
//
//  Created by Nicolas Seriot on 10/07/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DoubleMatrix : NSObject

@property (nonatomic) NSUInteger numberOfRows;
@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic) double *values;

- (id)initWithColumns:(NSUInteger)columns rows:(NSUInteger)rows;

+ (DoubleMatrix *)copyMatrix:(DoubleMatrix *)m;

- (void)setValue:(double)value atPoint:(NSPoint)p;
- (double)valueAtPoint:(NSPoint)p;

- (void)enumerateCellsAroundPoint:(NSPoint)p
                     withinRadius:(NSUInteger)radius
                            block:(void(^)(NSPoint p, double value))block;

- (double)sumOfCellsAroundPoint:(NSPoint)p withinRadius:(NSUInteger)radius;

- (void)findCellWithHighestValue:(void(^)(NSPoint p, double highestValue))block;
- (NSPoint)findPointWithHighestValue;

- (double)highestValue;

@end
