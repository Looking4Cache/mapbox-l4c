//
//  RMOverlayView.h
//  MapView
//
//  Created by Thorsten Heilmann on 07.03.13.
//
//

#import <Foundation/Foundation.h>

@class RMMapView;

@protocol RMStaticOverlayControlView <NSObject>

-(void)mapMove:(RMMapView *)mapView;
-(void)mapMoveEnd:(RMMapView *)mapView;
-(void)zoom;
-(void)zoomEnd;
-(void)updateHeading:(CLLocationDirection)heading;

@end
