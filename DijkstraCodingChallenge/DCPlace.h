//
//  DCPlace.h
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import "Mantle.h"

@interface DCPlace : MTLModel <MTLJSONSerializing>

@property(nonatomic, strong) NSString * placeId;
@property(nonatomic, strong) NSString * name;
@property(nonatomic, strong) NSString * icon;
@property(nonatomic, strong) NSString * vicinity;
@property float longitude;
@property float latitude;

@end
