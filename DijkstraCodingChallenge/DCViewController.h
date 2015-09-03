//
//  DCViewController.h
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface DCViewController : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate>

@property(nonatomic, strong) MKMapView * mapView;
@property(nonatomic, strong) CLLocation * currentLocation;
@property(nonatomic, strong) CLLocationManager * locationManager;

@property(nonatomic, strong) NSArray * places;
@end
