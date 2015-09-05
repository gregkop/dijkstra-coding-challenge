//
//  DCPlaceAnnotation.m
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import "DCPlaceAnnotation.h"

@implementation DCPlaceAnnotation

-(id)initWithPlace:(DCPlace *)place Location:(CLLocationCoordinate2D)location
{
    self = [super init];
    
    if(self)
    {
        _title = place.name;
        _place = place;
        _coordinate = location;
    }
    
    return self;
}

-(MKAnnotationView *)annotationView
{
    MKAnnotationView * annotationView = [[MKAnnotationView alloc]initWithAnnotation:self reuseIdentifier:@"DCPlacesAnnotation"];
    annotationView.enabled = YES;
    annotationView.canShowCallout = YES;
    annotationView.image = [UIImage imageNamed:@"beer"];
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeContactAdd];
    
    return annotationView;
}

@end
