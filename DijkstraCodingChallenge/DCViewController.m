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
#import "DCPlaceAnnotation.h"
#import "MJDijkstra.h"
#import "PESGraph.h"
#import "PESGraphNode.h"
#import "PESGraphEdge.h"
#import "PESGraphRoute.h"
#import "PESGraphRouteStep.h"

@interface DCViewController ()

@end


@implementation DCViewController

#pragma View Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Dijkstra Bar Hop!";
    
    [self constructScreen];
    [self setupLocationManagement];
}

- (void)constructScreen
{
    self.mapView = [[MKMapView alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    
    [self.view addSubview:self.mapView];
    
    self.selectionTableView = [[UITableView alloc]initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) * .9f, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) * .4f)];
    self.selectionTableView.dataSource = self;
    self.selectionTableView.delegate = self;
    self.selectionTableView.backgroundColor = [UIColor colorWithWhite:255 alpha:.8f];
    
    [self.view addSubview:self.selectionTableView];
}

-(void)animateTableState
{
    CGRect tableFrame = self.selectionTableView.frame;
    
    switch(self.screenState)
    {
        
        case NO_SELECTION:
        {
            tableFrame.origin.y = CGRectGetHeight(self.view.frame) * .9f;
            [UIView animateWithDuration:0.3f animations:^{
                self.selectionTableView.frame = tableFrame;
            }];
            
            break;
        }
            
        case START_SELECTED:
        {
            tableFrame.origin.y = CGRectGetHeight(self.view.frame) * .8f;
            [UIView animateWithDuration:0.3f animations:^{
                self.selectionTableView.frame = tableFrame;
            }];
            
            break;
        }
            
        case END_SELECTED:
        {
            tableFrame.origin.y = CGRectGetHeight(self.view.frame) * .6f;
            [UIView animateWithDuration:0.3f animations:^{
                self.selectionTableView.frame = tableFrame;
            }];
            
            break;
        }
        
        case TRIP_MAPPED:
        {
            break;
        }
    }
    
    [self.selectionTableView reloadData];
}

- (void)addPlacesToMap
{
    //Clear Existing Annotations
    [self.mapView removeAnnotations:[self.mapView annotations]];
    
    //Add new places
    for(DCPlace * place in self.places)
    {
        CLLocationCoordinate2D loc = CLLocationCoordinate2DMake(place.latitude, place.longitude);
        
        DCPlaceAnnotation * annotation = [[DCPlaceAnnotation alloc]initWithPlace:place Location:loc];
        
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
        [self animateTableState];
        
        [SVProgressHUD dismiss];
    } andFailBlock:^(NSURLSessionDataTask *task, NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Could not load places!"];
    }];
}

#pragma ActionButton methods
-(void)mapBarHop
{
    if(self.startingPlace && self.endingPlace)
        [self calculateDijkstraForStartPlace:self.startingPlace toEndPlace:self.endingPlace];
    
    self.screenState = TRIP_MAPPED;
    
    [self animateTableState];
}

-(void)resetTrip
{
    self.startingPlace = nil;
    self.endingPlace = nil;
    self.screenState = NO_SELECTION;
    [self.mapView removeOverlay:self.polyline];
    
    [self animateTableState];
    
}
#pragma Dijkstra related methods
-(NSNumber *)distanceBetweenPlace:(DCPlace *)place1 andPlace:(DCPlace *)place2
{
    CLLocation * location1 = [[CLLocation alloc]initWithLatitude:place1.latitude longitude:place1.longitude];
    CLLocation * location2 = [[CLLocation alloc]initWithLatitude:place2.latitude longitude:place2.longitude];
    
    return [NSNumber numberWithInt:[location1 distanceFromLocation:location2]];
}

- (void)calculateDijkstraForStartPlace:(DCPlace *)startPlace toEndPlace:(DCPlace *)endPlace
{
    PESGraph *graph = [[PESGraph alloc] init];
    
    for(int i = 0; i < self.places.count;i++)
    {
        NSMutableArray * placesArray = (NSMutableArray *)[self.places mutableCopy];
        
        DCPlace * place = [self.places objectAtIndex:i];
        
        [placesArray removeObjectAtIndex:i];
        
        NSMutableArray * objectsToCompare = [[NSMutableArray alloc]init];
        
        for(DCPlace * p in placesArray)
        {
            NSMutableDictionary * subGroup = [[NSMutableDictionary alloc]init];
            [subGroup setObject:[self distanceBetweenPlace:place andPlace:p] forKey:@"distance"];
            [subGroup setObject:p.placeId forKey:@"id"];
            
            [objectsToCompare addObject:subGroup];
        }
        
        NSSortDescriptor *sortDescriptor;
        sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"distance"
                                                     ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
        NSArray *sorted  = [objectsToCompare sortedArrayUsingDescriptors:sortDescriptors];
        
        PESGraphNode * aNode = [PESGraphNode nodeWithIdentifier:place.placeId];
        PESGraphNode * bNode = [PESGraphNode nodeWithIdentifier:[[sorted firstObject] objectForKey:@"id" ]];
        PESGraphNode * cNode = [PESGraphNode nodeWithIdentifier:[[sorted objectAtIndex:1] objectForKey:@"id" ]];
        PESGraphNode * dNode = [PESGraphNode nodeWithIdentifier:[[sorted objectAtIndex:2] objectForKey:@"id" ]];
        
        [graph addBiDirectionalEdge:[PESGraphEdge edgeWithName:[NSString stringWithFormat:@"%@-%@",place.placeId, [[sorted firstObject] objectForKey:@"id" ]] andWeight:[[sorted firstObject] objectForKey:@"distance" ] ] fromNode:aNode toNode:bNode];
        
        [graph addBiDirectionalEdge:[PESGraphEdge edgeWithName:[NSString stringWithFormat:@"%@-%@",place.placeId, [[sorted objectAtIndex:1] objectForKey:@"id" ]] andWeight:[[sorted objectAtIndex:1] objectForKey:@"distance" ] ] fromNode:aNode toNode:cNode];
        
        [graph addBiDirectionalEdge:[PESGraphEdge edgeWithName:[NSString stringWithFormat:@"%@-%@",place.placeId, [[sorted objectAtIndex:2] objectForKey:@"id" ]] andWeight:[[sorted objectAtIndex:2] objectForKey:@"distance" ] ] fromNode:aNode toNode:dNode];
        
    }
    
    PESGraphNode * startNode = [PESGraphNode nodeWithIdentifier:startPlace.placeId];
    PESGraphNode * endNode = [PESGraphNode nodeWithIdentifier:endPlace.placeId];
    
    
    PESGraphRoute *route = [graph shortestRouteFromNode:startNode toNode:endNode];
    
    CLLocationCoordinate2D coordinates[route.steps.count];
    int i = 0;
    
    for(PESGraphRouteStep * step in route.steps)
    {
        NSLog(@"node: %@", step.node.identifier);
        
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"placeId = %@",step.node.identifier];
        NSArray * result = [self.places filteredArrayUsingPredicate:predicate];
        
        DCPlace * place = [result lastObject];
        
        coordinates[i] = [[[CLLocation alloc]initWithLatitude:place.latitude longitude:place.longitude] coordinate];
        
        i++;
    }
    
    MKPolyline *oldPolyline = self.polyline;
    self.polyline = [MKPolyline polylineWithCoordinates:coordinates count:route.steps.count];
    
    [self.mapView addOverlay:self.polyline];
    if (oldPolyline)
        [self.mapView removeOverlay:oldPolyline];
}



#pragma UITableView Delegates
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return CGRectGetHeight(self.view.frame) * .1f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return CGRectGetHeight(self.view.frame) * .1f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CGRectGetHeight(self.view.frame) * .1f;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    self.tableHeaderView = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) * .1f)];
    
    if(self.screenState == NO_SELECTION)
        self.tableHeaderView.text = @"Select your first bar!";
    else if(self.screenState == START_SELECTED)
        self.tableHeaderView.text = @"Select your last bar!";
    else if(self.screenState == END_SELECTED)
        self.tableHeaderView.text = @"Map your bar hop!";
    else
        self.tableHeaderView.text = @"Reset below to map another bar hop.";
    
    self.tableHeaderView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    self.tableHeaderView.textColor  = [UIColor blackColor];
    self.tableHeaderView.textAlignment = NSTextAlignmentCenter;
    self.tableHeaderView.backgroundColor = [UIColor clearColor];
    
    return self.tableHeaderView;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    self.actionButton = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) * .1f)];
    
    if(self.screenState != TRIP_MAPPED)
    {
        [self.actionButton setTitle:@"Map my bar hop trip!" forState:UIControlStateNormal];
        [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.actionButton setBackgroundColor:[UIColor blueColor]];
        
        [self.actionButton addTarget:self action:@selector(mapBarHop) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [self.actionButton setTitle:@"Reset the trip" forState:UIControlStateNormal];
        [self.actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.actionButton setBackgroundColor:[UIColor grayColor]];
        
        [self.actionButton addTarget:self action:@selector(resetTrip) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return self.actionButton;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * tableCellIdentifier = @"TableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableCellIdentifier];
    
    if (cell == nil) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier];
        
    }
    
    if(indexPath.row == 0)
    {
        if(self.startingPlace)
        {
            cell.textLabel.text = [NSString stringWithFormat:@"Starting at %@",self.startingPlace.name];
        }
    }
    else if(indexPath.row == 1)
    {
        if(self.endingPlace)
        {
            cell.textLabel.text = [NSString stringWithFormat:@"Ending at %@", self.endingPlace.name];
        }
    }

    cell.imageView.image = [UIImage imageNamed:@"beer"];
    
    return cell;
}

#pragma UITableView Datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
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
            self.tableHeaderView.text = @"Could not access geolocation data.";
            
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
        self.tableHeaderView.text = @"Could not access geolocation data.";
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:@"Please make sure you have your GPS turned on."
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    } else {
        self.tableHeaderView.text = @"Could not access geolocation data.";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error retrieving location"
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    NSLog(@"title: %@", view.annotation.title);
    
    DCPlaceAnnotation * annotation = (DCPlaceAnnotation *)view.annotation;
    
    if(!self.startingPlace)
    {
        self.startingPlace = annotation.place;
        self.screenState = START_SELECTED;
    }
    else if(!self.endingPlace)
    {
        self.endingPlace = annotation.place;
        self.screenState = END_SELECTED;
    }
    
    [self animateTableState];
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        
        renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        renderer.lineWidth   = 3;
        
        return renderer;
    }
    
    return nil;
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
