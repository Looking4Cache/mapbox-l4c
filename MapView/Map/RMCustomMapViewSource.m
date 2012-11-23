//
//  OpenStreetMapsSource.h
//
// Copyright (c) 2008-2012, Route-Me Contributors
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

#import "RMCustomMapViewSource.h"

@implementation RMCustomMapViewSource
{
    RMFractalTileProjection *_tileProjection;
}

@synthesize minZoom = _minZoom, maxZoom = _maxZoom;

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    self.minZoom = 10;
    self.maxZoom = 22;
    
    return self;
}

- (id)initWithMapView:(RMMapView *)mapView andCustomMapView:(UIView<RMCustomMapView> *)customMapView
{
    if (!(self = [self init]))
        return nil;
    
    customMapView.userInteractionEnabled = NO;
    [mapView insertSubview:customMapView belowSubview:mapView.overlayView];
    mapView.customMapView = customMapView;
    
    return self;
}

- (void)cancelAllDownloads
{
    // no-op
}

- (void)dealloc
{
	[super dealloc];
}

- (NSUInteger)tileSideLength
{
    return 256;
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    return nil;
    //return [UIImage imageNamed:@"LoadingTile.png"];
}

- (NSURL *)URLForTile:(RMTile)tile
{
    return nil;
}

- (NSString *)tileURL:(RMTile)tile
{
    return nil;
}

- (NSString *)tileFile:(RMTile)tile
{
    return nil;
}

- (NSString *)tilePath
{
    return nil;
}

- (RMFractalTileProjection *)mercatorToTileProjection
{
    if ( ! _tileProjection)
    {
        _tileProjection = [[RMFractalTileProjection alloc] initFromProjection:self.projection
                                                               tileSideLength:self.tileSideLength
                                                                      maxZoom:self.maxZoom
                                                                      minZoom:self.minZoom];
    }
    
    return [[_tileProjection retain] autorelease];
}

- (RMProjection *)projection
{
	return [RMProjection googleProjection];
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
    return kDefaultLatLonBoundingBox;
}

- (NSString *)uniqueTilecacheKey
{
	return nil;
}

- (NSString *)shortName
{
	return @"OCM";
}

- (NSString *)longDescription
{
	return @"OpenCacheMap";
}

- (NSString *)shortAttribution
{
	return @"© OpenCacheMap CC-BY-SA";
}

- (NSString *)longAttribution
{
	return @"Map data © OpenCacheMap, licensed under Creative Commons Share Alike By Attribution.";
}

@end
