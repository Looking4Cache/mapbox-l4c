//
//  RMFastFileCache.h
//  MapView
//
//  Created by Thorsten Heilmann on 08.12.16.
//
//

#import <Foundation/Foundation.h>
#import "RMTileCache.h"

@interface RMFastFileCache : NSObject <RMTileCache, NSCacheDelegate>

+ (id)sharedInstance;

@end
