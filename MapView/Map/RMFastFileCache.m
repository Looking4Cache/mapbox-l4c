//
//  RMFastFileCache.m
//  MapView
//
//  Created by Thorsten Heilmann on 08.12.16.
//
//

#import "RMFastFileCache.h"
#import "OSCache.h"
#import <CommonCrypto/CommonDigest.h>

@interface RMFastFileCache ()
@property (strong, nonatomic) NSString *directory;
@property (strong, nonatomic) OSCache *imageNameCache;
@property (strong, nonatomic) OSCache *lastImageCache;
@end

@implementation RMFastFileCache

+ (id)sharedInstance
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (instancetype)init
{
    self = [super init];
    if ( self ) {
        // Directory to store the images
        self.directory = [NSString stringWithFormat:@"%@/MapCache", NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject];
        [[NSFileManager defaultManager] createDirectoryAtPath:self.directory withIntermediateDirectories:YES attributes:nil error:nil];
        
        // NSCache containing the filenames that are already stored
        self.imageNameCache = [[OSCache alloc] init];
        self.imageNameCache.countLimit = 250;
        self.imageNameCache.totalCostLimit = 60000;
        self.imageNameCache.evictsObjectsWithDiscardedContent = NO;
        self.imageNameCache.delegate = self;
        
        // Load the filenames already stored from the last sessions
        [self loadCurrentCachedFiles];
        
        // NSCache containing the last used images (if AdjustForRetinaDisplay is YES, each image will be requested four times)
        self.lastImageCache = [[OSCache alloc] init];
        self.lastImageCache.countLimit = 10;
    }
    return self;
}

- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)cacheKey
{
    // Try to load a maybe cached image
    return [self cachedImage:tile withCacheKey:cacheKey bypassingMemoryCache:NO];;
}

- (UIImage *)cachedImage:(RMTile)tile withCacheKey:(NSString *)cacheKey bypassingMemoryCache:(BOOL)shouldBypassMemoryCache
{
    // Try to load a maybe cached image
    UIImage *image;
    NSString *uuid = [self uuidForTile:tile withCacheKey:cacheKey];
    
    // Try to load from the memory cache
    if ( !shouldBypassMemoryCache ) {
        @synchronized (self.lastImageCache) {
            image = [self.lastImageCache objectForKey:uuid];
            if ( image ) {
                //NSLog(@"Loaded from memory: %@", uuid);
                return image;
            }
        }
    }
    
    // Try to load from the disk
    @synchronized (self.imageNameCache) {
        NSString *filePath = [self.imageNameCache objectForKey:uuid];
        if ( filePath ) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ( [fileManager fileExistsAtPath:filePath] ) {
                image = [UIImage imageWithContentsOfFile:filePath];
                //NSLog(@"Loaded: %@", uuid);
                
                // Store in memory cache (maybe reqsted several times
                if ( !shouldBypassMemoryCache ) {
                    if ( ![self.lastImageCache objectForKey:uuid] ) {
                        [self.lastImageCache setObject:image forKey:uuid];
                    }
                }
            }
        }
    }
    
    return image;
}

- (void)addImage:(UIImage *)image forTile:(RMTile)tile withCacheKey:(NSString *)cacheKey
{
    NSString *uuid = [self uuidForTile:tile withCacheKey:cacheKey];
    
    @synchronized (self.lastImageCache) {
        // Store in memory cache
        if ( ![self.lastImageCache objectForKey:uuid] ) {
            [self.lastImageCache setObject:image forKey:uuid];
        }
    }
    
    @synchronized (self.imageNameCache) {
        // Already stored on disk?
        if ( [self.imageNameCache objectForKey:uuid] ) {
            //NSLog(@"Skip store of %@", uuid);
            return;
        }
        
        // Write to disk
        //NSLog(@"Store: %@", uuid);
        NSString *filePath = [self.directory stringByAppendingPathComponent:uuid];
        NSData *imageData = UIImagePNGRepresentation(image);
        [imageData writeToFile:filePath atomically:NO];
        
        // Add to cache object
        [self.imageNameCache setObject:filePath forKey:uuid cost:0];
    }
}

- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    // The cache with the imagenames is full -> delete the oldest file
    if ( [cache isEqual:self.imageNameCache] ) {
        __block NSString *filePath = [(NSString *)obj copy];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW,0), ^{
            //NSLog(@"Delete: %lu, %@", (unsigned long)cache.countLimit, filePath);
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:filePath error:nil];
        });
    }
}

- (void)didReceiveMemoryWarning
{
    // Free in memory last-image cache
    [self.lastImageCache removeAllObjects];
}

- (void)loadCurrentCachedFiles
{
    // Loads the filenames of the current files in the NSCache, ordered by the creation date
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // List of all files in the cache directory
    NSError *error = nil;
    NSArray *filesArray = [fileManager contentsOfDirectoryAtPath:self.directory error:&error];
    if (error) {
        NSLog(@"Error in reading files: %@", [error localizedDescription]);
        return;
    }
    
    // Dict with filename and date
    NSMutableArray *filesAndProperties = [NSMutableArray arrayWithCapacity:[filesArray count]];
    for (NSString *file in filesArray) {
        NSError *error = nil;
        NSString *filePath = [self.directory stringByAppendingPathComponent:file];
        NSDictionary *properties = [fileManager attributesOfItemAtPath:filePath error:&error];
        NSDate *date = [properties objectForKey:NSFileCreationDate];
        if ( !error ) {
            [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:file, @"file", date, @"date", nil]];
        }
    }
    
    // sort using a block
    NSArray *sortedFiles = [filesAndProperties sortedArrayUsingComparator:
                            ^(id path1, id path2)
                            {
                                // compare
                                NSComparisonResult comp = [[path1 objectForKey:@"date"] compare:
                                                           [path2 objectForKey:@"date"]];
                                // invert ordering
                                if (comp == NSOrderedDescending) {
                                    comp = NSOrderedAscending;
                                }
                                else if(comp == NSOrderedAscending){
                                    comp = NSOrderedDescending;
                                }
                                return comp;
                            }];
    
    // Add to the cache
    for (NSDictionary *fileDict in sortedFiles) {
        NSString *fileName = [fileDict objectForKey:@"file"];
        NSString *filePath = [self.directory stringByAppendingPathComponent:fileName];
        [self.imageNameCache setObject:filePath forKey:fileName];
    }
}

- (void)removeAllCachedImages
{
    // Delete all cached images
    
    // Clear file list -> Image files will be deleted by the NSCache delegate
    [self.imageNameCache removeAllObjects];
    
    // Clear memory cache
    [self.lastImageCache removeAllObjects];
}

- (void)removeAllCachedImagesForCacheKey:(NSString *)cacheKey
{
    // Delete all, because we don´t have cacheKeys
    [self removeAllCachedImages];
}


# pragma mark - UUID generation

- (NSString *)uuidForTile:(RMTile)tile withCacheKey:(NSString *)cacheKey
{
    return stringWithUUIDBytes(UUIDBytesFromMD5HashOfString([NSString stringWithFormat:@"%@%lld", cacheKey, RMTileKey(tile)]));
}

NSString *stringWithUUIDBytes(CFUUIDBytes UUIDBytes) {
    NSString *UUIDString = nil;
    CFUUIDRef UUIDRef = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, UUIDBytes);
    
    if (UUIDRef != NULL) {
        UUIDString = (__bridge_transfer NSString *)CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
        CFRelease(UUIDRef);
    }
    
    return UUIDString;
}

CFUUIDBytes UUIDBytesFromMD5HashOfString(NSString *MD5Hash) {
    const char *UTF8String = [MD5Hash UTF8String];
    CFUUIDBytes UUIDBytes;
    
    CC_MD5(UTF8String, (CC_LONG)strlen(UTF8String), (unsigned char*)&UUIDBytes);
    
    return UUIDBytes;
}

@end
