//
//  RMOSMScoutSource.m
//  MapView
//
//  Created by Thorsten Heilmann on 01.08.13.
//
//

#import "RMOSMScoutSource.h"

@implementation RMOSMScoutSource

- (id)initWithRenderer:(id<RMExternalTileRenderer>)renderer
{
	if (!(self = [super init]))
        return nil;
    
    self.externalRenderer = renderer;
    renderQueue = dispatch_queue_create("com.looking4cache.l4cpro.osmscout", DISPATCH_QUEUE_SERIAL);
    self.maxZoom = 20;
    
	return self;
}

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    __block UIImage *image = nil;
	tile = [[self mercatorToTileProjection] normaliseTile:tile];
    
    // Versuchen aus Cache zu ermitteln
    image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];
    if ( image )
        return image;
    
    // Coordinate (Mitte des Tile) berechnen
    RMProjectedRect planetBounds = self.projection.planetBounds;
    double scale = (1<<tile.zoom);
    double tileMetersPerPixel = planetBounds.size.width / (self.tileSideLength * scale);
    double paddedTileSideLength = self.tileSideLength + (2.0 * kTileSidePadding);
    CGPoint bottomLeft = CGPointMake((tile.x * self.tileSideLength) - kTileSidePadding,
                                     ((scale - tile.y - 1) * self.tileSideLength) - kTileSidePadding);   
    double modifier = ( paddedTileSideLength * tileMetersPerPixel ) / 2;
    double x = (bottomLeft.x * tileMetersPerPixel) - fabs(planetBounds.origin.x) + modifier;
    double y = (bottomLeft.y * tileMetersPerPixel) - fabs(planetBounds.origin.y) + modifier;
    CLLocationCoordinate2D coord = [self.projection projectedPointToCoordinate:RMProjectedPointMake(x,y)];
   
    // Tile berechnen
    dispatch_sync(renderQueue, ^{
        image = [self.externalRenderer renderImageForCoordiante:coord scale:scale];
    });
    
    // Cachen
    if ( image )
        [tileCache addImage:image forTile:tile withCacheKey:[self uniqueTilecacheKey]];
    
	return image;
}

- (NSString *)uniqueTilecacheKey
{
	return self.externalRenderer.uniqueTilecacheKey;
}

- (NSUInteger)tileSideLength
{
    return kDefaultTileSize;
}

- (NSString *)shortName
{
	return @"OSMScout";
}

- (NSString *)longDescription
{
	return @"OSMScout";
}

- (NSString *)shortAttribution
{
	return @"OSMScout";
}

- (NSString *)longAttribution
{
	return @"OSMScout";
}

@end
