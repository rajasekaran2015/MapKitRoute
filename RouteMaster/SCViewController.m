/*
 Copyright 2013 Scott Logic Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import "SCViewController.h"
#import "SCStepsViewController.h"
#import "SCAppDelegate.h"

@interface SCViewController () <MKMapViewDelegate> {
    MKPolyline *_routeOverlay;
    MKRoute *_currentRoute;
}
@end

@implementation SCViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self updateUserCurrentLocation];
    
    self.activityIndicator.hidden = YES;
    self.routeDetailsButton.hidden = YES;
    self.routeDetailsButton.enabled = NO;
    self.mapView.delegate = self;
    self.mapView.scrollEnabled = YES;
    self.mapView.zoomEnabled = YES;
    self.mapView.userTrackingMode = YES;
    self.mapView.showsUserLocation = YES;
    self.navigationItem.title = @"RouteMaster";
    
}

- (void)updateUserCurrentLocation {
    if (nil == _locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
    }
    
    _locationManager.delegate = self;

    // This part was added due to a location authorization issue on iOS8
    // See more at: http://nevan.net/2014/09/core-location-manager-changes-in-ios-8/
    if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [_locationManager requestAlwaysAuthorization];
    }
    
    self.mapView.showsUserLocation = YES;
    
    [_locationManager startUpdatingLocation];
    
    CLLocation *currentLocation = _locationManager.location;
    if (currentLocation) {
        SCAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        appDelegate.currentLocation = currentLocation;
    }
}

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return UIInterfaceOrientationMaskPortrait;
//}

- (IBAction)handleRoutePressed:(id)sender {
    // We're working
    self.activityIndicator.hidden = NO;
    [self.activityIndicator startAnimating];
    self.routeButton.enabled = NO;
    self.routeDetailsButton.enabled = NO;
    
    // Make a directions request
    MKDirectionsRequest *directionsRequest = [MKDirectionsRequest new];
    // Start at our current location
    MKMapItem *source = [MKMapItem mapItemForCurrentLocation];
    [directionsRequest setSource:source];
    // Make the destination
    CLLocationCoordinate2D destinationCoords = CLLocationCoordinate2DMake(38.8977, -77.0365);
    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:destinationCoords addressDictionary:nil];
    MKMapItem *destination = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];
    [directionsRequest setDestination:destination];
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:directionsRequest];
    [directions calculateDirectionsWithCompletionHandler:^(MKDirectionsResponse *response, NSError *error) {
        // We're done
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
        self.routeButton.enabled = YES;
        
        // Now handle the result
        if (error) {
            NSLog(@"There was an error getting your directions");
            return;
        }
        
        // So there wasn't an error - let's plot those routes
        self.routeDetailsButton.enabled = YES;
        self.routeDetailsButton.hidden = NO;
        _currentRoute = [response.routes firstObject];
        [self.mapView setVisibleMapRect:_currentRoute.polyline.boundingMapRect animated:YES];
        [self plotRouteOnMap:_currentRoute];
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[SCStepsViewController class]]) {
        SCStepsViewController *vc = (SCStepsViewController *)segue.destinationViewController;
        vc.route = _currentRoute;
    }
}

#pragma mark - Utility Methods
- (void)plotRouteOnMap:(MKRoute *)route
{
    if(_routeOverlay) {
        [self.mapView removeOverlay:_routeOverlay];
    }
    
    // Update the ivar
    _routeOverlay = route.polyline;
    
    // Add it to the map
    [self.mapView addOverlay:_routeOverlay];
    
}


#pragma mark - MKMapViewDelegate methods
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 4.0;
    return  renderer;
}

-(void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation     *)userLocation
{
    //CLLocationCoordinate2D loc = [userLocation coordinate];
    //MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(loc, 1000, 1000);
    //[self.mapView setRegion:region animated:YES];
    
    
    //Zoom map to users current location
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    
    span.latitudeDelta = 0.00001;
    span.longitudeDelta = 0.00001;
    
    CLLocationCoordinate2D location = mapView.userLocation.coordinate;
    
    region.span = span;
    region.center = location;
    
    [mapView setRegion:region animated:TRUE];
    [mapView regionThatFits:region];
    
}

@end
