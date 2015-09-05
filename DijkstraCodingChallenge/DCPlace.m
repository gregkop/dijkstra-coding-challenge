//
//  DCPlace.m
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import "DCPlace.h"

@implementation DCPlace

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"placeId" : @"id",
             @"name": @"name",
             @"vicinity": @"vicinity",
             @"longitude": @"geometry.location.lng",
             @"latitude": @"geometry.location.lat",
             @"icon" : @"icon"
             };
}

@end
