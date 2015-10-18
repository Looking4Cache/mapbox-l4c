//
//  OpenStreetMapsSource.m
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

#import "RMHillshadeTileSource.h"
#import "FMDB.h"

@implementation RMHillshadeTileSource
{
    NSMutableDictionary *_databaseQueues;
}

- (id)init
{
    if (!(self = [super init]))
        return nil;
    
    // min / max zoom
    self.minZoom = 4;
    self.maxZoom = 12;
    
    // init database queues
    _databaseQueues = [[NSMutableDictionary alloc] init];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:@"N49E009.hill"];
    [queue inDatabase:^(FMDatabase *db) {
        [db setShouldCacheStatements:YES];
    }];

    [_databaseQueues setObject:queue forKey:@"N49E009"];
    
    return self;
}

/*- (NSURL *)URLForTile:(RMTile)tile
{
    if ( tile.zoom < self.minZoom && tile.zoom > self.maxZoom ) return nil;
    
    //NSLog(@"%@",[NSString stringWithFormat:@"http://offlinemap.info/world//%d/%d/%d.png", tile.zoom, tile.x, tile.y]);
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://offlinemap.info/world/%d/%d/%d.png", tile.zoom, tile.x, tile.y]];
}*/

- (UIImage *)imageForTile:(RMTile)tile inCache:(RMTileCache *)tileCache
{
    __block UIImage *image = nil;
    
    tile = [[self mercatorToTileProjection] normaliseTile:tile];
    
    // get database queue
    NSString *filekey = @"N49E009";
    FMDatabaseQueue *queue = [_databaseQueues objectForKey:filekey];
    
    // fetch the image from the db
    [queue inDatabase:^(FMDatabase *db) {
         NSString *query = [NSString stringWithFormat:@"SELECT image FROM tiles WHERE z = %d AND x = %d AND y = %d", tile.zoom, tile.x, tile.y];
         FMResultSet *result = [db executeQuery:query];
         
         if ([db hadError])
             NSLog(@"DB error %d on line %d: %@", [db lastErrorCode], __LINE__, [db lastErrorMessage]);
         
         if ([result next])
             image = [[UIImage alloc] initWithData:[result dataForColumnIndex:0]];
         else
             image = [RMTileImage missingTile];
         
         [result close];
     }];

    return image;
}

- (NSString *)uniqueTilecacheKey
{
    return @"L4CHillshade";
}

- (NSString *)shortName
{
    return @"L4CHillshade";
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
