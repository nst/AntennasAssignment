//
//  Matrix.m
//  ObjCAntennas
//
//  Created by Nicolas Seriot on 10/07/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import "DoubleMatrix.h"

@implementation DoubleMatrix

- (id)initWithColumns:(NSUInteger)columns rows:(NSUInteger)rows {
    self = [super init];
    
    self.numberOfRows = rows;
    self.numberOfColumns = columns;
    
    _values = calloc(columns * rows, sizeof(double));
    
    return self;
}

+ (DoubleMatrix *)copyMatrix:(DoubleMatrix *)src {
    DoubleMatrix *dst = [[DoubleMatrix alloc] initWithColumns:src.numberOfColumns rows:src.numberOfRows];
    
    memcpy(dst.values, dst.values, src.numberOfColumns * src.numberOfRows * sizeof(double));
    
    return dst;
}

- (void)setValue:(double)value atPoint:(NSPoint)p {
    NSUInteger i = [self indexForPoint:p];
    _values[i] = value;
}

- (NSUInteger)indexForPoint:(NSPoint)p {
    return (NSUInteger)p.y * _numberOfColumns + (NSUInteger)p.x;
}

- (double)valueAtPoint:(NSPoint)p {
    NSUInteger i = [self indexForPoint:p];
    return _values[i];
}

- (double)sumOfCellsAroundPoint:(NSPoint)p withinRadius:(NSUInteger)radius {
    
    double sum = 0.0;
    double radiusAsDouble = (double)radius;
    
    NSUInteger xMin = MAX(0, p.x - radius);
    NSUInteger yMin = MAX(0, p.y - radius);
    
    NSUInteger xMax = MIN(p.x + radius + 1, _numberOfColumns);
    NSUInteger yMax = MIN(p.y + radius + 1, _numberOfRows);
    
    for(NSUInteger x_ = xMin; x_ < xMax; x_++) {
        for(NSUInteger y_ = yMin; y_ < yMax; y_++) {
            
            NSInteger deltaX = x_ - p.x;
            NSInteger deltaY = y_ - p.y;
            
            NSUInteger squaredDistance = deltaX*deltaX + deltaY*deltaY;
            
            double distance = sqrt(1.0 * squaredDistance);
            
            if(distance <= radiusAsDouble) {
                NSPoint p2 = NSMakePoint((double)x_, (double)y_);
                
                double value = [self valueAtPoint:p2];
                
                if(value > 0.0) {
                    sum += value;
                }
            }
        }
        
    }
    
    return sum;

}

- (void)enumerateCellsAroundPoint:(NSPoint)p withinRadius:(NSUInteger)radius block:(void(^)(NSPoint p, double value))block {
    
    NSUInteger xMin = MAX(0, p.x - radius);
    NSUInteger yMin = MAX(0, p.y - radius);
    
    NSUInteger xMax = MIN(p.x + radius + 1, _numberOfColumns);
    NSUInteger yMax = MIN(p.y + radius + 1, _numberOfRows);
    
    for(NSUInteger x_ = xMin; x_ < xMax; x_++) {
        for(NSUInteger y_ = yMin; y_ < yMax; y_++) {
            
            NSInteger deltaX = x_ - p.x;
            NSInteger deltaY = y_ - p.y;
            
            NSUInteger squaredDistance = deltaX*deltaX + deltaY*deltaY;
            
            double distance = sqrt(1.0 * squaredDistance);
            
            if(distance <= (double)radius) {
                NSPoint p2 = NSMakePoint((double)x_, (double)y_);
                
                double value = [self valueAtPoint:p2];
                
                block(p2, value);
            }
        }
        
    }
}

- (double)highestValue {
    double highest = 0.0;
    for(NSUInteger x = 0; x < self.numberOfColumns; x++) {
        for(NSUInteger y = 0; y < self.numberOfRows; y++) {
            NSPoint p = NSMakePoint(x, y);
            double value = [self valueAtPoint:p];
            highest = MAX(value, highest);
        }
    }
    return highest;
}

- (NSPoint)findPointWithHighestValue {
    double highestValue = 0.0;
    NSPoint highestPoint = NSZeroPoint;
    for(NSUInteger x = 0; x < self.numberOfColumns; x++) {
        for(NSUInteger y = 0; y < self.numberOfRows; y++) {
            NSPoint p = NSMakePoint(x, y);
            double value = [self valueAtPoint:p];
            if(value > highestValue) {
                highestValue = value;
                highestPoint = p;
            }
        }
    }
    return highestPoint;
}

- (void)findCellWithHighestValue:(void(^)(NSPoint p, double highestValue))block {
    double highestValue = 0.0;
    NSPoint highestPoint = NSZeroPoint;
    for(NSUInteger x = 0; x < self.numberOfColumns; x++) {
        for(NSUInteger y = 0; y < self.numberOfRows; y++) {
            NSPoint p = NSMakePoint(x, y);
            double value = [self valueAtPoint:p];
            if(value > highestValue) {
                highestValue = value;
                highestPoint = p;
            }
        }
    }
    block(highestPoint, highestValue);
}

- (void)dealloc {
    if(_values) {
        free(_values);
        _values = nil;
    }
}

@end
