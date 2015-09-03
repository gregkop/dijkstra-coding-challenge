//
//  DCPlaceAnnotation.h
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mapkit/Mapkit.h>

@interface DCPlaceAnnotation : NSObject <MKAnnotation>

@property(nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property(copy, nonatomic) NSString * title;

- (id)initWithTitle:(NSString*)locationTitle Location:(CLLocationCoordinate2D)location;
- (MKAnnotationView *)annotationView;

@end
