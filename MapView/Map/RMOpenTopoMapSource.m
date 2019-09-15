//
//  RMOpenTopoMapSource.m
//  MapView
//
//  Created by Thorsten Heilmann on 15.09.19.
//

#import "RMOpenTopoMapSource.h"

@implementation RMOpenTopoMapSource

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    self.minZoom = 1;
    self.maxZoom = 17;
    
    return self;
}

- (NSURL *)URLForTile:(RMTile)tile
{
    // L4C : Weiter rein zoomen
    NSAssert4(((tile.zoom >= self.minZoom) && (tile.zoom <= self.maxZoom)),
              @"%@ tried to retrieve tile with zoomLevel %d, outside source's defined range %f to %f",
              self, tile.zoom, self.minZoom, self.maxZoom);
    
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://b.tile.opentopomap.org/%d/%d/%d.png", tile.zoom, tile.x, tile.y]];
}

- (NSString *)uniqueTilecacheKey
{
    return @"OpenTopoMap";
}

- (NSString *)shortName
{
    return @"Open Topo Map";
}

- (NSString *)longDescription
{
    return @"";
}

- (NSString *)shortAttribution
{
    return @"";
}

- (NSString *)longAttribution
{
    return @"";
}

@end
