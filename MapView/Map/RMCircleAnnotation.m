//
//  RMCircleAnnotation.m
//  MapView
//
// Copyright (c) 2008-2013, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMCircleAnnotation.h"

#import "RMCircle.h"

#define kDefaultLineColor [UIColor blackColor]
#define kDefaultFillColor [UIColor colorWithRed:0 green:0.5 blue:1.0 alpha:0.25]

@implementation RMCircleAnnotation

@synthesize radiusInMeters=_radiusInMeters;
@synthesize lineColor=_lineColor;
@synthesize fillColor=_fillColor;
@synthesize lineDashed=_lineDashed;

- (id)initWithMapView:(RMMapView *)aMapView centerCoordinate:(CLLocationCoordinate2D)centerCoordinate radiusInMeters:(CGFloat)radiusInMeters
{
    if (!(self = [super initWithMapView:aMapView points:[NSArray arrayWithObject:[[CLLocation alloc] initWithLatitude:centerCoordinate.latitude longitude:centerCoordinate.longitude]]]))
        return nil;
    
    _radiusInMeters = radiusInMeters;
    
    self.lineColor = kDefaultLineColor;
    self.fillColor = kDefaultFillColor;
    
    return self;
}

- (void)setLayer:(RMMapLayer *)newLayer
{
    if ( ! newLayer)
        [super setLayer:nil];
    else
        RMLog(@"Setting a custom layer on an %@ is a no-op", [self class]);
}

- (RMMapLayer *)layer
{
    if ( ! [super layer]) {
        RMCircle *circle = [[RMCircle alloc] initWithView:self.mapView radiusInMeters:_radiusInMeters];
        circle.latitude = self.centerCoordinate.latitude;
        circle.fillColor = self.fillColor;
        circle.lineColor = self.lineColor;
        circle.lineDashed = self.lineDashed;
        super.layer = circle;
    }
    
    return [super layer];
}

- (CLLocationCoordinate2D)centerCoordinate
{
    return self.coordinate;
}

- (void)setLineWidthInPixels:(CGFloat)lineWidthInPixels
{
    [(RMCircle *)[self layer] setLineWidthInPixels:lineWidthInPixels];
}

- (CGFloat)lineWidthInPixels
{
    return ((RMCircle *)[self layer]).lineWidthInPixels;
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    [self setLineWidthInPixels:lineWidth];
}

- (CGFloat)lineWidth
{
    return [self lineWidthInPixels];
}

- (UIColor *)lineColor
{
    return _lineColor;
}

- (void)setLineColor:(UIColor *)lineColor
{
    _lineColor = lineColor;
    [(RMCircle *)[self layer] setLineColor:lineColor];
}

- (UIColor *)fillColor
{
    return _fillColor;
}

- (void)setFillColor:(UIColor *)fillColor
{
    _fillColor = fillColor;
    [(RMCircle *)[self layer] setFillColor:fillColor];
}

- (BOOL)lineDashed
{
    return _lineDashed;
}

- (void)setLineDashed:(BOOL)lineDashed
{
    _lineDashed = lineDashed;
    [(RMCircle *)[self layer] setLineDashed:lineDashed];
}


- (void)setRadiusInMeters:(CGFloat)radiusInMeters
{
    [(RMCircle *)[self layer] setRadiusInMeters:radiusInMeters];
}

- (CGFloat)radiusInMeters
{
    return [((RMCircle *)[self layer]) radiusInMeters];
}

@end
