//
//  DCPlaceAnnotation.h
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mapkit/Mapkit.h>
#import "DCPlace.h"

@interface DCPlaceAnnotation : NSObject <MKAnnotation>

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(copy, nonatomic) NSString * title;
@property(strong, nonatomic) DCPlace * place;

- (id)initWithPlace:(DCPlace *)place Location:(CLLocationCoordinate2D)location;
- (MKAnnotationView *)annotationView;

@end
