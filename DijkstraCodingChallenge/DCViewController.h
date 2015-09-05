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
#import "DCPLace.h"

@interface DCViewController : UIViewController <MKMapViewDelegate,CLLocationManagerDelegate,UITableViewDelegate,UITableViewDataSource>

typedef enum stateTypes
{
    NO_SELECTION,
    START_SELECTED,
    END_SELECTED,
    TRIP_MAPPED
} ScreenState;

@property(nonatomic, strong) MKMapView * mapView;
@property(nonatomic, strong) CLLocation * currentLocation;
@property(nonatomic, strong) CLLocationManager * locationManager;
@property(nonatomic, strong) MKPolyline * polyline;
@property(nonatomic, strong) UITableView * selectionTableView;
@property(nonatomic, strong) UILabel * tableHeaderView;
@property(nonatomic, strong) UIButton * actionButton;
@property(nonatomic, strong) NSArray * places;
@property(nonatomic, strong) DCPlace * startingPlace;
@property(nonatomic, strong) DCPlace * endingPlace;
@property ScreenState screenState;

@end
