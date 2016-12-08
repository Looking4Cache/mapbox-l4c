//
//  RMFICache.m
//  MapView
//
//  Created by Thorsten Heilmann on 08.12.16.
//
//

#import "RMFICache.h"
#import "FICImageCache.h"
#import "FICEntity.h"

@interface RMFICache ()
@property (strong, nonatomic) FICImageCache *imageCache;
@end

@implementation RMFICache

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        self.imageCache = [FICImageCache sharedImageCache];
        
        FICImageFormat *imageFormat256 = [[FICImageFormat alloc] init];
        imageFormat256.name = @"com.looking4cache.osm.tiles.256";
        imageFormat256.family = @"com.looking4cache.osm.tiles";
        imageFormat256.style = FICImageFormatStyle32BitBGR;
        imageFormat256.imageSize = CGSizeMake(256, 256);
        imageFormat256.maximumCount = 250;
        imageFormat256.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
        imageFormat256.protectionMode = FICImageFormatProtectionModeNone;

        FICImageFormat *imageFormat512 = [[FICImageFormat alloc] init];
        imageFormat512.name = @"com.looking4cache.osm.tiles.515";
        imageFormat512.family = @"com.looking4cache.osm.tiles";
        imageFormat512.style = FICImageFormatStyle32BitBGR;
        imageFormat512.imageSize = CGSizeMake(512, 512);
        imageFormat512.maximumCount = 250;
        imageFormat512.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
        imageFormat512.protectionMode = FICImageFormatProtectionModeNone;

        self.imageCache.formats = @[imageFormat256, imageFormat512];
    }
    return self;
}



@end
