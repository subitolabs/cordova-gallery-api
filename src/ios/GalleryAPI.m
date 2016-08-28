#import <Cordova/CDV.h>
#import "CDVFile.h"

#import "GalleryAPI.h"

@interface GalleryAPI ()

@end

@implementation GalleryAPI

- (void) getAlbums:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        NSDictionary *subtypes = [GalleryAPI subtypes];
        __block NSMutableArray *albums = [[NSMutableArray alloc] init];
        __block NSDictionary *cameraRoll;
        
        NSArray *collectionTypes = @[
                                     @{@"title" : @"smart", @"type" : [NSNumber numberWithInteger: PHAssetCollectionTypeSmartAlbum]},
                                     @{@"title" : @"album", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum]}
                                     ];
        
        for (NSDictionary *collectionType in collectionTypes)
        {
            [[PHAssetCollection fetchAssetCollectionsWithType:[[collectionType objectForKey:@"type"] integerValue] subtype:PHAssetCollectionSubtypeAny options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
             {
                 if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil && ([subtypes.allKeys indexOfObject:@(collection.assetCollectionSubtype)] != NSNotFound))
                 {
                     PHFetchResult* result = [PHAsset fetchAssetsInAssetCollection:collection
                                                                           options:nil];
                     if (result.count > 0) {
                         if ([collection.localizedTitle isEqualToString:@"Camera Roll"] && collection.assetCollectionType == PHAssetCollectionTypeSmartAlbum) {
                             cameraRoll = @{
                                            @"id" : collection.localIdentifier,
                                            @"title" : collection.localizedTitle,
                                            @"type" : subtypes[@(collection.assetCollectionSubtype)],
                                            @"assets" : [NSString stringWithFormat:@"%ld", (long) collection.estimatedAssetCount]
                                            };
                         } else {
                             [albums addObject:@{
                                                 @"id" : collection.localIdentifier,
                                                 @"title" : collection.localizedTitle,
                                                 @"type" : subtypes[@(collection.assetCollectionSubtype)],
                                                 @"assets" : [NSString stringWithFormat:@"%ld", (long) collection.estimatedAssetCount]
                                                 }];
                         }
                     }
                 }
             }];
        }
        
        if (cameraRoll)
            [albums insertObject:cameraRoll atIndex:0];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:albums];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) getMedia:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        NSDictionary *subtypes = [GalleryAPI subtypes];
        NSDictionary *album = [command argumentAtIndex:0];
        __block NSMutableArray *assets = [[NSMutableArray alloc] init];
        __block PHImageRequestOptions * imageRequestOptions = [[PHImageRequestOptions alloc] init];
        imageRequestOptions.synchronous = YES;
        imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        
        PHFetchResult *collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[album[@"id"]]
                                                                                          options:nil];
        
        if (collections && collections.count > 0) {
            PHAssetCollection *collection = collections[0];
            [[PHAsset fetchAssetsInAssetCollection:collection
                                           options:nil] enumerateObjectsUsingBlock:^(PHAsset *obj, NSUInteger idx, BOOL *stop)
             {
                 [assets addObject:@{
                                     @"id" : obj.localIdentifier,
                                     @"title" : @"",
                                     @"orientation" : @"up",
                                     @"lat" : @4,
                                     @"lng" : @5,
                                     @"width" : [NSNumber numberWithFloat:obj.pixelWidth],
                                     @"height" : [NSNumber numberWithFloat:obj.pixelHeight],
                                     @"size" : @0,
                                     @"data" : @"",
                                     @"thumbnail" : @"",
                                     @"error" : @"false",
                                     @"type":subtypes[@(collection.assetCollectionSubtype)]
                                     }];
             }];
        }
        
        NSArray* reversedAssests = [[assets reverseObjectEnumerator] allObjects];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:reversedAssests];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) getMediaThumbnail:(CDVInvokedUrlCommand*)command {
    // Check command.arguments here.
    [self.commandDelegate runInBackground:^{
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        
        NSMutableDictionary *media = [command argumentAtIndex:0];
        
        NSString *imageId = [media[@"id"] stringByReplacingOccurrencesOfString:@"/" withString:@"^"];
        NSString* docsPath = [NSTemporaryDirectory() stringByStandardizingPath];
        NSString* thumbnailPath = [NSString stringWithFormat:@"%@/%@_mthumb.png", docsPath, imageId];
        
        NSFileManager* fileMgr = [[NSFileManager alloc] init];
        
        media[@"thumbnail"] = thumbnailPath;
        if ([fileMgr fileExistsAtPath:thumbnailPath])
            NSLog(@"file exist");
        else {
            NSLog(@"file doesn't exist");
            media[@"error"] = @"true";
            
            PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[media[@"id"]]
                                                                     options:nil];
            if (assets && assets.count > 0) {
                [[PHImageManager defaultManager] requestImageForAsset:assets[0]
                                                           targetSize:CGSizeMake(300, 300)
                                                          contentMode:PHImageContentModeAspectFill
                                                              options:options
                                                        resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                            if (result)
                                                            {
                                                                NSError* err = nil;
                                                                if ([UIImagePNGRepresentation(result) writeToFile:thumbnailPath
                                                                                                          options:NSAtomicWrite
                                                                                                            error:&err])
                                                                    media[@"error"] = @"false";
                                                                else {
                                                                    if (err)
                                                                    {
                                                                        media[@"thumbnail"] = @"";
                                                                        NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                    }
                                                                }
                                                            }
                                                        }];
            } else {
                if ([media[@"type"] isEqualToString:@"PHAssetCollectionSubtypeAlbumMyPhotoStream"]) {
                    
                    [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                              subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream
                                                              options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
                     {
                         if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil)
                         {
                             [[PHAsset fetchAssetsInAssetCollection:collection
                                                            options:nil] enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                 if ([obj.localIdentifier isEqualToString:media[@"id"]]) {
                                     [[PHImageManager defaultManager] requestImageForAsset:obj
                                                                                targetSize:CGSizeMake(300, 300)
                                                                               contentMode:PHImageContentModeAspectFill
                                                                                   options:options
                                                                             resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                                                 if (result)
                                                                                 {
                                                                                     NSError* err = nil;
                                                                                     if ([UIImagePNGRepresentation(result) writeToFile:thumbnailPath
                                                                                                                               options:NSAtomicWrite
                                                                                                                                 error:&err])
                                                                                         media[@"error"] = @"false";
                                                                                     else {
                                                                                         if (err)
                                                                                         {
                                                                                             media[@"thumbnail"] = @"";
                                                                                             NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                                         }
                                                                                     }
                                                                                 }
                                                                             }];
                                 }
                             }];
                         }
                     }];
                }
            }
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:media];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) getHQImageData:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        NSMutableDictionary *media = [command argumentAtIndex:0];
        
        NSString* docsPath = [NSTemporaryDirectory() stringByStandardizingPath];
        NSString* hqImageURLPath = [NSString stringWithFormat:@"%@/hqImage.png", docsPath];
        
        media[@"HQImageUrl"] = hqImageURLPath;

        media[@"error"] = @"true";
        
        PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[media[@"id"]]
                                                                 options:nil];
        if (assets && assets.count > 0) {
            [[PHImageManager defaultManager] requestImageDataForAsset:assets[0]
                                                              options:options
                                                        resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                            if (imageData)
                                                            {
                                                                NSError* err = nil;
                                                                if ([imageData writeToFile:hqImageURLPath
                                                                                   options:NSAtomicWrite
                                                                                     error:&err])
                                                                    media[@"error"] = @"false";
                                                                else {
                                                                    if (err)
                                                                    {
                                                                        media[@"HQImageUrl"] = @"";
                                                                        NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                    }
                                                                }
                                                            }
                                                        }];
        } else {
            if ([media[@"type"] isEqualToString:@"PHAssetCollectionSubtypeAlbumMyPhotoStream"]) {
                
                [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                          subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream
                                                          options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
                 {
                     if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil)
                     {
                         [[PHAsset fetchAssetsInAssetCollection:collection
                                                        options:nil] enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                             if ([obj.localIdentifier isEqualToString:media[@"id"]]) {
                                 [[PHImageManager defaultManager] requestImageDataForAsset:assets[0]
                                                                                   options:options
                                                                             resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                                                                 if (imageData)
                                                                                 {
                                                                                     NSError* err = nil;
                                                                                     if ([imageData writeToFile:hqImageURLPath
                                                                                                        options:NSAtomicWrite
                                                                                                          error:&err])
                                                                                         media[@"error"] = @"false";
                                                                                     else {
                                                                                         if (err)
                                                                                         {
                                                                                             media[@"HQImageUrl"] = @"";
                                                                                             NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                                         }
                                                                                     }
                                                                                 }
                                                                             }];
                             }
                         }];
                     }
                 }];
            }
        }
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                      messageAsDictionary:media];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}


+ (NSDictionary *) subtypes {
    NSDictionary *subtypes = @{@(PHAssetCollectionSubtypeAlbumRegular): @"PHAssetCollectionSubtypeAlbumRegular",
                               @(PHAssetCollectionSubtypeAlbumImported): @"PHAssetCollectionSubtypeAlbumImported",
                               @(PHAssetCollectionSubtypeAlbumMyPhotoStream): @"PHAssetCollectionSubtypeAlbumMyPhotoStream",
                               @(PHAssetCollectionSubtypeAlbumCloudShared): @"PHAssetCollectionSubtypeAlbumCloudShared",
                               @(PHAssetCollectionSubtypeSmartAlbumFavorites): @"PHAssetCollectionSubtypeSmartAlbumFavorites",
                               @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded): @"PHAssetCollectionSubtypeSmartAlbumRecentlyAdded",
                               @(PHAssetCollectionSubtypeSmartAlbumUserLibrary): @"PHAssetCollectionSubtypeSmartAlbumUserLibrary",
                               @(PHAssetCollectionSubtypeSmartAlbumSelfPortraits): @"PHAssetCollectionSubtypeSmartAlbumSelfPortraits",
                               @(PHAssetCollectionSubtypeSmartAlbumScreenshots): @"PHAssetCollectionSubtypeSmartAlbumScreenshots"
                               };
    return subtypes;
}

+ (NSString*)cordovaVersion
{
    return CDV_VERSION;
}

@end
