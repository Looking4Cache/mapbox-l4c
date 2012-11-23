//
// RMDBMapSource.m
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

#import "RMDBRMapsSource.h"
#import "RMTileImage.h"
#import "RMTileCache.h"
#import "RMFractalTileProjection.h"
#import "FMDatabase.h"
#import "FMDatabaseQueue.h"

#pragma mark --- begin constants ----

// mandatory preference keys
#define kMinZoomKey @"map.minZoom"
#define kMaxZoomKey @"map.maxZoom"
#define kTileSideLengthKey @"map.tileSideLength"

// optional preference keys for the coverage area
#define kCoverageTopLeftLatitudeKey @"map.coverage.topLeft.latitude"
#define kCoverageTopLeftLongitudeKey @"map.coverage.topLeft.longitude"
#define kCoverageBottomRightLatitudeKey @"map.coverage.bottomRight.latitude"
#define kCoverageBottomRightLongitudeKey @"map.coverage.bottomRight.longitude"
#define kCoverageCenterLatitudeKey @"map.coverage.center.latitude"
#define kCoverageCenterLongitudeKey @"map.coverage.center.longitude"

// optional preference keys for the attribution
#define kShortNameKey @"map.shortName"
#define kLongDescriptionKey @"map.longDescription"
#define kShortAttributionKey @"map.shortAttribution"
#define kLongAttributionKey @"map.longAttribution"

#pragma mark --- end constants ----

@interface RMDBRMapsSource (Preferences)

- (NSString *)getPreferenceAsString:(NSString *)name;
- (float)getPreferenceAsFloat:(NSString *)name;
- (int)getPreferenceAsInt:(NSString *)name;

@end

#pragma mark -

@implementation RMDBRMapsSource
{
    FMDatabaseQueue *_queue;
    
    // coverage area
    CLLocationCoordinate2D _topLeft;
    CLLocationCoordinate2D _bottomRight;
    CLLocationCoordinate2D _center;
    
    NSString *_uniqueTilecacheKey;
    NSUInteger _tileSideLength;
}

- (id)initWithPath:(NSString *)path
{
	if (!(self = [super init]))
        return nil;
    
    _uniqueTilecacheKey = [[[path lastPathComponent] stringByDeletingPathExtension] retain];
    
    _queue = [[FMDatabaseQueue databaseQueueWithPath:path] retain];
    
    if ( ! _queue)
    {
        RMLog(@"Error opening db map source %@", path);
        return nil;
    }
    
    [_queue inDatabase:^(FMDatabase *db) {
        [db setShouldCacheStatements:YES];
        
        // Debug mode
        // [db setTraceExecution:YES];
    }];
    
    RMLog(@"Opening db map source %@", path);
    
    // get the tile side length
    _tileSideLength = 256;
    
    // get the supported zoom levels
    self.minZoom = 1;
    self.maxZoom = [self getPreferenceAsInt:@"minzoom"];
    if ( self.maxZoom != INT_MIN ) {
        self.maxZoom = (self.maxZoom - 17 ) * -1;
    } else {
        self.maxZoom = 18;
    }
    
	return self;
}

- (void)dealloc
{
    [_uniqueTilecacheKey release]; _uniqueTilecacheKey = nil;
    [_queue release]; _queue = nil;
    [super dealloc];
}


#pragma mark RMTileSource methods

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    __block UIImage *image = nil;
	tile = [[self mercatorToTileProjection] normaliseTile:tile];
    int z = (tile.zoom * -1) + 17;
    //NSLog(@"tile: %u %u %u",tile.x, tile.y, z);
    image = [tileCache cachedImage:tile withCacheKey:[self uniqueTilecacheKey]];
    
    if (image)
        return image;

    [_queue inDatabase:^(FMDatabase *db)
     {
         // fetch the image from the db
         int z = (tile.zoom * -1) + 17;
         NSString *select = [NSString stringWithFormat:@"select image from tiles where x = %d and y = %d and z = %d", tile.x, tile.y, z];
         FMResultSet *result = [db executeQuery:select];

         if ([db hadError])
             NSLog(@"DB error %d on line %d: %@", [db lastErrorCode], __LINE__, [db lastErrorMessage]);
         
         if ([result next]) {
             image = [[[UIImage alloc] initWithData:[result dataForColumnIndex:0]] autorelease];
             //NSLog(@"select: %@",select);
         } else {
             image = [RMTileImage missingTile];
             //NSLog(@"missing %@",select);
         }
         
         [result close];
     }];
    
    if (image)
        [tileCache addImage:image forTile:tile withCacheKey:[self uniqueTilecacheKey]];
    
	return image;
}

- (RMSphericalTrapezium)latitudeLongitudeBoundingBox
{
	return kMBTilesDefaultLatLonBoundingBox;
}

- (NSUInteger)tileSideLength
{
    return _tileSideLength;
}

- (NSString *)uniqueTilecacheKey
{
    return _uniqueTilecacheKey;
}

- (NSString *)shortName
{
	return [self getPreferenceAsString:kShortNameKey];
}

- (NSString *)longDescription
{
	return [self getPreferenceAsString:kLongDescriptionKey];
}

- (NSString *)shortAttribution
{
	return [self getPreferenceAsString:kShortAttributionKey];
}

- (NSString *)longAttribution
{
	return [self getPreferenceAsString:kLongAttributionKey];
}

#pragma mark preference methods

- (NSString *)getPreferenceAsString:(NSString*)name
{
	__block NSString* value = nil;
    
    [_queue inDatabase:^(FMDatabase *db)
     {
         FMResultSet *result = [db executeQuery:@"select %@ from info", name];
         
         if ([result next])
             value = [result stringForColumn:name];
         
         [result close];
     }];
    
	return value;
}

- (float)getPreferenceAsFloat:(NSString *)name
{
	NSString *value = [self getPreferenceAsString:name];
	return (value == nil) ? INT_MIN : [value floatValue];
}

- (int)getPreferenceAsInt:(NSString *)name
{
	NSString* value = [self getPreferenceAsString:name];
	return (value == nil) ? INT_MIN : [value intValue];
}

@end
