#import <Cordova/CDV.h>

#import "GalleryAPI.h"

@interface GalleryAPI ()

@end

@implementation GalleryAPI

- (void) getAlbums:(CDVInvokedUrlCommand*)command
{
    __block NSMutableArray *albums = [[NSMutableArray alloc] init];
    NSArray *collectionTypes = @[
                                 @{@"title" : @"smart", @"type" : [NSNumber numberWithInteger: PHAssetCollectionTypeSmartAlbum]},
                                 @{@"title" : @"album", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum]},
                                 @{@"title" : @"moment", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeMoment]}
    ];
    
    for (NSDictionary *collectionType in collectionTypes)
    {
        [[PHAssetCollection fetchAssetCollectionsWithType:[[collectionType objectForKey:@"type"] integerValue] subtype:PHAssetCollectionSubtypeAny options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
         {
             if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil)
             {
                 [albums addObject:@{
                                     @"id" : collection.localIdentifier,
                                     @"title" : collection.localizedTitle,
                                     @"type" : [collectionType objectForKey:@"title"],
                                     @"assets" : [NSString stringWithFormat:@"%ld", (long) collection.estimatedAssetCount]
                                     }];
             }
         }];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:albums];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getMedia:(CDVInvokedUrlCommand*)command
{
    NSString *album = [command argumentAtIndex:0];
    __block NSMutableArray *assets = [[NSMutableArray alloc] init];
    __block PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
    
    imageRequestOptions.synchronous = YES;
    
    NSArray *collectionTypes = @[
                                 @{@"title" : @"smart", @"type" : [NSNumber numberWithInteger: PHAssetCollectionTypeSmartAlbum]},
                                 @{@"title" : @"album", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum]},
                                 @{@"title" : @"moment", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeMoment]}
                                 ];
    
    for (NSDictionary *collectionType in collectionTypes)
    {
        [[PHAssetCollection fetchAssetCollectionsWithType:[[collectionType objectForKey:@"type"] integerValue] subtype:PHAssetCollectionSubtypeAny options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
         {
             if (collection != nil && collection.localizedTitle != nil && [album isEqualToString:collection.localizedTitle])
             {
                 [[PHAsset fetchAssetsInAssetCollection:collection options:nil] enumerateObjectsUsingBlock:^(PHAsset *obj, NSUInteger idx, BOOL *stop)
                 {
                     [[PHImageManager defaultManager]
                      requestImageDataForAsset:obj
                      options:imageRequestOptions
                      resultHandler:^(NSData *imageData, NSString *dataUTI,
                                      UIImageOrientation orientation,
                                      NSDictionary *info)
                      {
                          NSString *filename = @"";
                          NSString *path = @"";
                          
                          if ([info objectForKey:@"PHImageFileUTIKey"])
                          {
                              filename = [info objectForKey:@"PHImageFileUTIKey"];
                          }
                          
                          if ([info objectForKey:@"PHImageFileURLKey"])
                          {
                              path = [[info objectForKey:@"PHImageFileURLKey"] absoluteString];
                          }
                          
                          [assets addObject:@{
                                              @"id" : obj.localIdentifier,
                                              @"title" : filename,
                                              @"orientation" : @"up",
                                              @"lat" : @4,
                                              @"lng" : @5,
                                              @"width" : [NSNumber numberWithFloat:obj.pixelWidth],
                                              @"height" : [NSNumber numberWithFloat:obj.pixelHeight],
                                              @"size" : @0,
                                              @"data" : path,
                                              @"thumbnail" : @""
                                              }];
                      }];
                 }];
             }
         }];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:assets];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

+ (NSString*)cordovaVersion
{
    return CDV_VERSION;
}

@end
