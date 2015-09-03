//
//  DCViewController.m
//  DijkstraCodingChallenge
//
//  Created by Greg on 9/2/15.
//  Copyright (c) 2015 Greg. All rights reserved.
//

#import "DCViewController.h"
#import "GooglePlacesAPIClient.h"
#import "SVProgressHUD.h"
#import "DCPlace.h"
#import "DCPlaceAnnotation.h"

@interface DCViewController ()

@end

@implementation DCViewController

#pragma View Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self constructScreen];
    [self setupLocationManagement];
    // Do any additional setup after loading the view.
}

- (void)constructScreen
{
    self.mapView = [[MKMapView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
}

- (void)addPlacesToMap
{
    //Clear Existing Annotations
    [self.mapView removeAnnotations:[self.mapView annotations]];
    
    //Add new places
    for(DCPlace * place in self.places)
    {
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(place.latitude, place.longitude);
        
        DCPlaceAnnotation * annotation = [[DCPlaceAnnotation alloc]initWithTitle:place.name Location:loc];
        
        [self.mapView addAnnotation:annotation];
    }
}

#pragma mark Network Calls
#pragma mark - Network Calls
-(void)loadPlacesData
{
    GooglePlacesAPIClient * client = [GooglePlacesAPIClient sharedHTTPClient];
    [SVProgressHUD showWithStatus:@"Loading..." maskType:SVProgressHUDMaskTypeBlack];
    
    __weak DCViewController *weakSelf = self;
    
    [client fetchPlacesWithLongitude:self.currentLocation.coordinate.longitude andLatitude:self.currentLocation.coordinate.latitude withSuccessBlock:^(NSURLSessionDataTask *task, NSArray * placesResults) {
        
        weakSelf.places = placesResults;
        
        [self addPlacesToMap];
        
        [SVProgressHUD dismiss];
    } andFailBlock:^(NSURLSessionDataTask *task, NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Could not load places!"];
    }];
}

#pragma Location Management
#pragma mark CLLocationManagerDelegate methods and helpers
-(void)setupLocationManagement
{
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
}

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        _locationManager.distanceFilter = kCLLocationAccuracyHundredMeters;
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    switch (status) {
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        {
            NSLog(@"kCLAuthorizationStatusAuthorized");
            
            [self.locationManager startUpdatingLocation];
        }
            break;
        case kCLAuthorizationStatusDenied:
            NSLog(@"kCLAuthorizationStatusDenied");
        {
            //self.locationStatusLabel.text = @"Could not access geolocation data.";
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"We can’t access your current location.\n\nTo view nearby bars at your current location, turn on access to your location in the Settings app under Location Services." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alertView show];
            
        }
            break;
        case kCLAuthorizationStatusNotDetermined:
        {
            NSLog(@"kCLAuthorizationStatusNotDetermined");
        }
            break;
        case kCLAuthorizationStatusRestricted:
        {
            NSLog(@"kCLAuthorizationStatusRestricted");
        }
            break;
        default:break;
    }
}

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    self.currentLocation = newLocation;
    
    __weak DCViewController *weakSelf = self;
    
   
    [self loadPlacesData];
    
    [self.mapView setCenterCoordinate:  self.currentLocation.coordinate animated:YES];
    
    MKCoordinateRegion region;
    
    region = MKCoordinateRegionMake(self.currentLocation.coordinate, MKCoordinateSpanMake(.02, .02));
    
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"Error: %@", [error description]);
    
    if (error.code == kCLErrorDenied) {
        [self.locationManager stopUpdatingLocation];
    } else if (error.code == kCLErrorLocationUnknown) {
        //self.locationStatusLabel.text = @"Could not access geolocation data.";
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:@"Please make sure you have your GPS turned on."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    } else {
        //self.locationStatusLabel.text = @"Could not access geolocation data.";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if([annotation isKindOfClass:[DCPlaceAnnotation class]])
    {
        DCPlaceAnnotation * placeAnnotation = (DCPlaceAnnotation *)annotation;
        
        MKAnnotationView * annotationView = [self.mapView dequeueReusableAnnotationViewWithIdentifier:@"DCPlaceAnnotation"];
        
        if(annotationView == nil)
        {
            annotationView = placeAnnotation.annotationView;
        }
        else
        {
            annotationView.annotation = annotation;
        }
        
        return annotationView;
    }
    else
        return nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
