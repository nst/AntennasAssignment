//
//  NSBitmapImageRep+ObjCAntennas.h
//  ObjCAntennas
//
//  Created by Nicolas Seriot on 10/07/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DoubleMatrix.h"

@interface NSBitmapImageRep (ObjCAntennas)

- (double)intensityAtPoint:(NSPoint)point;

- (DoubleMatrix *)doubleMatrix;

- (void)updateWithDoubleMatrix:(DoubleMatrix *)m;

@end
