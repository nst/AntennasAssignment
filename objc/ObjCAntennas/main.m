//
//  main.m
//  ObjCAntennas
//
//  Created by Nicolas Seriot on 10/07/14.
//  Copyright (c) 2014 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "DoubleMatrix.h"
#import "NSBitmapImageRep+ObjCAntennas.h"

#define WRITE_IMAGES 1

id contentsOfJSONFileAtPath(NSString *path) {
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSError *error = nil;
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(json == nil) {
        NSLog(@"-- error: %@", error);
    }
    return json;
}

double totalPopulation(NSBitmapImageRep *popGridImage) {
    NSSize size = popGridImage.size;
    
    double sum = 0.0;
    
    for(NSUInteger x = 0; x < size.width; x++) {
        for(NSUInteger y = 0; y < size.height; y++) {
            NSPoint point = NSMakePoint(x, y);
            double value = [popGridImage intensityAtPoint:point];
            sum += value;
        }
    }
    
    return sum;
}

double countCoveredPeople(NSBitmapImageRep *popGridImage, DoubleMatrix *populationCoverageCountMatrix) {
    
    NSSize size = popGridImage.size;
    
    double coveredPeople = 0.0;
    
    for (NSUInteger x = 0; x < size.width; x++) {
        for (NSUInteger y = 0; y < size.height; y++) {
            NSPoint p = NSMakePoint(x, y);
            if([populationCoverageCountMatrix valueAtPoint:p] > 0.0) {
                coveredPeople += [popGridImage intensityAtPoint:p];
            }
        }
    }
    
    return coveredPeople;
}

void evaluateSolution(NSString *antennasAndBudgetPath,
                      NSString *popImagePath,
                      NSString *costImagePath,
                      NSArray *solution,
                      void(^solutionDetailsBlock)(double totalCost, double totalPop, double coveredPop, double coveredPopPercent)) {
    /**/
    
    NSDictionary *antennasAndBudgetDictionary = contentsOfJSONFileAtPath(antennasAndBudgetPath);
    assert(antennasAndBudgetDictionary);
    //NSLog(@"-- %@", antennasAndBudgetDictionary);
    
    /**/
    
    NSImage *popImage = [[NSImage alloc] initWithContentsOfFile:popImagePath];
    assert(popImage);
    NSBitmapImageRep *popGridImage = [NSBitmapImageRep imageRepWithData:[popImage TIFFRepresentation]];
    
    /**/
    
    NSImage *costImage = [[NSImage alloc] initWithContentsOfFile:costImagePath];
    assert(costImage);
    NSBitmapImageRep *costGridImage = [NSBitmapImageRep imageRepWithData:[costImage TIFFRepresentation]];
    
    /**/
    
    BOOL sameSizes = NSEqualSizes(popImage.size, costImage.size);
    assert(sameSizes);
    
    /**/
    
    NSDictionary *antennasDictionary = antennasAndBudgetDictionary[@"antennas"];
    
    /**/
    
    double totalCost = 0.0;
    
    DoubleMatrix *populationCoverageCountMatrix = [[DoubleMatrix alloc] initWithColumns:costGridImage.size.width rows:costGridImage.size.height];
    
    for (NSArray *typeAndCoordsXY in solution) {
        NSString *antennaType = typeAndCoordsXY[0];
        NSNumber *antennaXNumber = typeAndCoordsXY[1];
        NSNumber *antennaYNumber = typeAndCoordsXY[2];
        
        NSUInteger antennaX = [antennaXNumber unsignedIntegerValue];
        NSUInteger antennaY = [antennaYNumber unsignedIntegerValue];
        
        NSNumber *powerNumber = antennasDictionary[antennaType][@"power"];
        NSUInteger power = [powerNumber unsignedIntegerValue];
        
        NSPoint p = NSMakePoint(antennaX, antennaY);
        
        double cost = [costGridImage intensityAtPoint:p];
        totalCost += cost;
        
        [populationCoverageCountMatrix enumerateCellsAroundPoint:p
                                                    withinRadius:power
                                                           block:^(NSPoint p, double value) {
                                                               [populationCoverageCountMatrix setValue:(value+1.0) atPoint:p];
                                                           }];
    }
    
    double coveredPeople = countCoveredPeople(popGridImage, populationCoverageCountMatrix);
    
    double totalPop = totalPopulation(popGridImage);
    
    double coveredPeoplePercent = 100.0 * coveredPeople / totalPop;
    
    solutionDetailsBlock(totalCost, totalPop, coveredPeople, coveredPeoplePercent);
}

void updateBenefitsMatrix(DoubleMatrix *benefitsMatrix, DoubleMatrix *uncoveredPopMatrix, NSUInteger power) {
    for(NSUInteger x = 0; x < benefitsMatrix.numberOfColumns; x++) {
        for(NSUInteger y = 0; y < benefitsMatrix.numberOfRows; y++) {
            NSPoint point = NSMakePoint(x, y);
            
            double benefit = [uncoveredPopMatrix sumOfCellsAroundPoint:point withinRadius:power];
            
            [benefitsMatrix setValue:benefit atPoint:point];
        }
    }
}

void writeCurrentCoverageImage(NSBitmapImageRep *popGridImage, NSBitmapImageRep *costGridImage, DoubleMatrix *uncoveredPopMatrix, NSString *path) {
    NSBitmapImageRep *popGridImageCopy = [popGridImage copy];
    
    for(NSUInteger x = 0; x < popGridImageCopy.size.width; x++) {
        for(NSUInteger y = 0; y < popGridImageCopy.size.height; y++) {
            NSPoint p = NSMakePoint(x, y);
            
            NSUInteger pixel[4] = {0,0,0,0};
            
            BOOL isCovered = [uncoveredPopMatrix valueAtPoint:p] == -1.0;
            
            if(isCovered) {
                // (r, g, b) = ( cost * 255.0, p * 255.0, 0 )
                NSUInteger costPixel[4];
                [costGridImage getPixel:costPixel atX:x y:y];
                
                NSUInteger popPixel[4];
                [popGridImage getPixel:popPixel atX:x y:y];
                
                pixel[0] = 255 - costPixel[0];
                pixel[1] = 255 - popPixel[0];
                pixel[2] = 0;
                pixel[3] = 255;
                
            } else {
                double value = [uncoveredPopMatrix valueAtPoint:p];
                double pixelValue = value * 255;
                
                pixel[0] = (NSUInteger)pixelValue;
                pixel[1] = (NSUInteger)pixelValue;
                pixel[2] = (NSUInteger)pixelValue;
                pixel[3] = 255;
            }
            
            [popGridImageCopy setPixel:pixel atX:x y:y];
        }
    }
    
    NSData *pngData = [popGridImageCopy representationUsingType:NSPNGFileType properties:nil];
    [pngData writeToFile:path atomically:YES];
    NSLog(@"-- wrote %@", path);
}

NSArray* solve(NSString *antennasAndBudgetPath, NSString *popImagePath, NSString *costImagePath, NSString *outDirectoryPath) {
    
    NSDictionary *antennasAndBudgetDictionary = contentsOfJSONFileAtPath(antennasAndBudgetPath);
    assert(antennasAndBudgetDictionary);
    
    NSImage *popImage = [[NSImage alloc] initWithContentsOfFile:popImagePath];
    assert(popImage);
    NSBitmapImageRep *popGridImage = [NSBitmapImageRep imageRepWithData:[popImage TIFFRepresentation]];
    
    NSImage *costImage = [[NSImage alloc] initWithContentsOfFile:costImagePath];
    assert(costImage);
    NSBitmapImageRep *costGridImage = [NSBitmapImageRep imageRepWithData:[costImage TIFFRepresentation]];
    
    NSSize size = popImage.size;

    NSDictionary *antennasDictionary = antennasAndBudgetDictionary[@"antennas"];
    NSNumber *budgetNumber = antennasAndBudgetDictionary[@"budget"];
    double budget = [budgetNumber doubleValue];
    
    /**/
    
    NSMutableArray *antennaTypes = [[antennasDictionary allKeys] mutableCopy];
    [antennaTypes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *k1 = (NSString *)obj1;
        NSString *k2 = (NSString *)obj2;
        
        NSNumber *power1 = [antennasDictionary valueForKey:k1][@"power"];
        NSNumber *power2 = [antennasDictionary valueForKey:k2][@"power"];
        
        return [power2 compare:power1];
    }];
    
    /*
     - for each antenna type, sorted by power descending:
     ..- build benefits grid
     ..- for each antenna of this type:
     ....- put in on best location that fits budget
     ....- update the benefits grid
     */
    
    double totalCost = 0.0;
    
    NSMutableArray *solution = [NSMutableArray array];
    
    DoubleMatrix *uncoveredPopMatrix = [popGridImage doubleMatrix];
    
    for(NSString *type in antennaTypes) {
        NSDictionary *antenna = antennasDictionary[type];
        NSNumber *antennaPowerNumber = antenna[@"power"];
        NSNumber *antennaQuantityNumber = antenna[@"qty"];
        NSUInteger power = [antennaPowerNumber unsignedIntegerValue];
        NSUInteger quantity = [antennaQuantityNumber unsignedIntegerValue];
        
        // build benefits grid
        
        DoubleMatrix *benefitsMatrix = [[DoubleMatrix alloc] initWithColumns:size.width rows:size.height];
        
        // update benefits grid
        
        updateBenefitsMatrix(benefitsMatrix, uncoveredPopMatrix, power);
        
        NSLog(@"-- %@", antenna);
        
        // for each antenna of this type
        for(NSUInteger i = 0; i < quantity; i++) {
            // put in on best location that fits budget
            
            NSPoint pointWithHighestValue = [benefitsMatrix findPointWithHighestValue];
            
            double highestValue = [benefitsMatrix valueAtPoint:pointWithHighestValue];
            
            double cost = [costGridImage intensityAtPoint:pointWithHighestValue];
            
            BOOL antennaIsTooExpensive = totalCost + cost > budget;

            if(antennaIsTooExpensive) {
                NSLog(@"-- skipping antenna with cost %f because %f + %f > budget %f", cost, totalCost, cost, budget);
            } else {
                totalCost += cost;
                
                NSLog(@"  %@ [%lu] --> %@ %f", type, i, NSStringFromPoint(pointWithHighestValue), highestValue);
                
                NSArray *solutionItem = @[type, @((NSUInteger)pointWithHighestValue.x), @((NSUInteger)pointWithHighestValue.y)];
                [solution addObject:solutionItem];
            }
            
            [uncoveredPopMatrix enumerateCellsAroundPoint:pointWithHighestValue
                                             withinRadius:power
                                                    block:^(NSPoint p, double value) {
                                                        [uncoveredPopMatrix setValue:-1.0 atPoint:p];
                                                    }];
            
            updateBenefitsMatrix(benefitsMatrix, uncoveredPopMatrix, power);
        }
        
        if(WRITE_IMAGES) {
            NSString *path = [NSString stringWithFormat:@"/tmp/%@.png", type];
            writeCurrentCoverageImage(popGridImage, costGridImage, uncoveredPopMatrix, path);
        }
    }
    
    return solution;
}

void writeSolution(NSArray *solution, NSString *path) {
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:solution options:NSJSONWritingPrettyPrinted error:&error];
    if(jsonData == nil) {
        NSLog(@"-- %@", error);
        return;
    }
    
    [jsonData writeToFile:path atomically:YES];
    NSLog(@"-- wrote %@", path);
}

NSArray* readSolution(NSString *path) {
    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    
    NSError *error = nil;
    NSArray *solution = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
    
    if(solution == nil) {
        NSLog(@"-- error: %@", error);
    }
    return solution;
}

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        
        NSString *antennasAndBudgetPath = @"/Users/nst/Projects/AntennasAssignment/data/antennas_and_budget.json";
        NSString *popImagePath = @"/Users/nst/Projects/AntennasAssignment/data/pop.png";
        NSString *costImagePath = @"/Users/nst/Projects/AntennasAssignment/data/cost.png";
        NSString *solutionPath = @"/Users/nst/Projects/AntennasAssignment/results/solution.json";
        
#if 0
        NSString *outDirectoryPath = @"/Users/nst/Projects/AntennasAssignment/results/";
        NSArray *solution = solve(antennasAndBudgetPath, popImagePath, costImagePath, outDirectoryPath);
        writeSolution(solution, solutionPath);
#else
        NSArray *solution = readSolution(solutionPath);
#endif
        
        /**/
        
        evaluateSolution(antennasAndBudgetPath,
                         popImagePath,
                         costImagePath,
                         solution,
                         ^(double totalCost, double totalPop, double coveredPop, double coveredPopPercent) {
                             NSLog(@"-- totalCost: %f", totalCost);
                             NSLog(@"-- totalPop: %f", totalPop);
                             NSLog(@"-- coveredPop: %f", coveredPop);
                             NSLog(@"-- coveredPopPercent: %f", coveredPopPercent);
                         });
        
    }
    return 0;
}

