#import <Cordova/CDV.h>

#import "GalleryAPI.h"

#define kDirectoryName @"mendr"

@interface GalleryAPI ()

@end

@implementation GalleryAPI

- (void) checkPermission:(CDVInvokedUrlCommand*)command {
    [self.commandDelegate runInBackground:^{
        __block NSDictionary *result;
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        
        if (status == PHAuthorizationStatusAuthorized) {
            // Access has been granted.
            result = @{@"success":@(true), @"message":@"Authorized"};
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                        callbackId:command.callbackId];
        }
        
        else if (status == PHAuthorizationStatusDenied) {
            // Access has been denied.
            result = @{@"success":@(false), @"message":@"Denied"};
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                        callbackId:command.callbackId];
        }
        
        else if (status == PHAuthorizationStatusNotDetermined) {
            
            // Access has not been determined.
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                
                if (status == PHAuthorizationStatusAuthorized) {
                    // Access has been granted.
                    result = @{@"success":@(true), @"message":@"Authorized"};
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                                callbackId:command.callbackId];
                }
                
                else {
                    // Access has been denied.
                    result = @{@"success":@(false), @"message":@"Denied"};
                    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                                callbackId:command.callbackId];
                }
            }];
        }
        
        else if (status == PHAuthorizationStatusRestricted) {
            // Restricted access - normally won't happen.
            result = @{@"success":@(false), @"message":@"Restricted"};
            [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result]
                                        callbackId:command.callbackId];
        }
    }];
}

- (void)getAlbums:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        NSDictionary* subtypes = [GalleryAPI subtypes];
        __block NSMutableArray* albums = [[NSMutableArray alloc] init];
        __block NSDictionary* cameraRoll;
        
        NSArray* collectionTypes = @[
                                     @{ @"title" : @"smart",
                                        @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeSmartAlbum] },
                                     @{ @"title" : @"album",
                                        @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum] }
                                     ];
        
        for (NSDictionary* collectionType in collectionTypes) {
            [[PHAssetCollection fetchAssetCollectionsWithType:[collectionType[@"type"] integerValue] subtype:PHAssetCollectionSubtypeAny options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection* collection, NSUInteger idx, BOOL* stop) {
                if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil && ([subtypes.allKeys indexOfObject:@(collection.assetCollectionSubtype)] != NSNotFound)) {
                    PHFetchResult* result = [PHAsset fetchAssetsInAssetCollection:collection
                                                                          options:nil];
                    if (result.count > 0) {
                        if ([collection.localizedTitle isEqualToString:@"Camera Roll"] && collection.assetCollectionType == PHAssetCollectionTypeSmartAlbum) {
                            cameraRoll = @{
                                           @"id" : collection.localIdentifier,
                                           @"title" : collection.localizedTitle,
                                           @"type" : subtypes[@(collection.assetCollectionSubtype)],
                                           @"assets" : [NSString stringWithFormat:@"%ld", (long)collection.estimatedAssetCount]
                                           };
                        }
                        else {
                            [albums addObject:@{
                                                @"id" : collection.localIdentifier,
                                                @"title" : collection.localizedTitle,
                                                @"type" : subtypes[@(collection.assetCollectionSubtype)],
                                                @"assets" : [NSString stringWithFormat:@"%ld", (long)collection.estimatedAssetCount]
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

- (void)getMedia:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        NSDictionary* subtypes = [GalleryAPI subtypes];
        NSDictionary* album = [command argumentAtIndex:0];
        __block NSMutableArray* assets = [[NSMutableArray alloc] init];
        __block PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.networkAccessAllowed = true;
        
        PHFetchResult* collections = [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[ album[@"id"] ]
                                                                                          options:nil];
        
        if (collections && collections.count > 0) {
            PHAssetCollection* collection = collections[0];
            [[PHAsset fetchAssetsInAssetCollection:collection
                                           options:nil] enumerateObjectsUsingBlock:^(PHAsset* obj, NSUInteger idx, BOOL* stop) {
                if (obj.mediaType == PHAssetMediaTypeImage)
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
                                        @"type" : subtypes[@(collection.assetCollectionSubtype)]
                                        }];
            }];
        }
        
        NSArray* reversedAssests = [[assets reverseObjectEnumerator] allObjects];
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:reversedAssests];
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)getMediaThumbnail:(CDVInvokedUrlCommand*)command
{
    // Check command.arguments here.
    [self.commandDelegate runInBackground:^{
        
        PHImageRequestOptions* options = [PHImageRequestOptions new];
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.networkAccessAllowed = true;

        NSMutableDictionary* media = [command argumentAtIndex:0];
        
        NSString* imageId = [media[@"id"] stringByReplacingOccurrencesOfString:@"/" withString:@"^"];
        NSString* docsPath = [NSTemporaryDirectory() stringByStandardizingPath];
        NSString* thumbnailPath = [NSString stringWithFormat:@"%@/%@_mthumb.png", docsPath, imageId];
        
        NSFileManager* fileMgr = [[NSFileManager alloc] init];
        
        media[@"thumbnail"] = thumbnailPath;
        if ([fileMgr fileExistsAtPath:thumbnailPath])
            NSLog(@"file exist");
        else {
            NSLog(@"file doesn't exist");
            media[@"error"] = @"true";
            
            PHFetchResult* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[ media[@"id"] ]
                                                                     options:nil];
            if (assets && assets.count > 0) {
                [[PHImageManager defaultManager] requestImageForAsset:assets[0]
                                                           targetSize:CGSizeMake(300, 300)
                                                          contentMode:PHImageContentModeAspectFill
                                                              options:options
                                                        resultHandler:^(UIImage* _Nullable result, NSDictionary* _Nullable info) {
                                                            if (result) {
                                                                NSError* err = nil;
                                                                if ([UIImagePNGRepresentation(result) writeToFile:thumbnailPath
                                                                                                          options:NSAtomicWrite
                                                                                                            error:&err])
                                                                    media[@"error"] = @"false";
                                                                else {
                                                                    if (err) {
                                                                        media[@"thumbnail"] = @"";
                                                                        NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                    }
                                                                }
                                                            }
                                                        }];
            }
            else {
                if ([media[@"type"] isEqualToString:@"PHAssetCollectionSubtypeAlbumMyPhotoStream"]) {
                    
                    [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                              subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream
                                                              options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection* collection, NSUInteger idx, BOOL* stop) {
                        if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil) {
                            [[PHAsset fetchAssetsInAssetCollection:collection
                                                           options:nil] enumerateObjectsUsingBlock:^(PHAsset* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                                if ([obj.localIdentifier isEqualToString:media[@"id"]]) {
                                    [[PHImageManager defaultManager] requestImageForAsset:obj
                                                                               targetSize:CGSizeMake(300, 300)
                                                                              contentMode:PHImageContentModeAspectFill
                                                                                  options:options
                                                                            resultHandler:^(UIImage* _Nullable result, NSDictionary* _Nullable info) {
                                                                                if (result) {
                                                                                    NSError* err = nil;
                                                                                    if ([UIImagePNGRepresentation(result) writeToFile:thumbnailPath
                                                                                                                              options:NSAtomicWrite
                                                                                                                                error:&err])
                                                                                        media[@"error"] = @"false";
                                                                                    else {
                                                                                        if (err) {
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

- (void)getHQImageData:(CDVInvokedUrlCommand*)command
{
    [self.commandDelegate runInBackground:^{
        
        PHImageRequestOptions* options = [PHImageRequestOptions new];
        options.synchronous = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeNone;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = true;
        
        NSString* mediaURL = nil;
        
        NSMutableDictionary* media = [command argumentAtIndex:0];
        
        NSString* docsPath = [[NSTemporaryDirectory() stringByStandardizingPath] stringByAppendingPathComponent:kDirectoryName];
        NSError* error;
        
        NSFileManager* fileMgr = [NSFileManager new];
        
        BOOL canCreateDirectory = false;
        
        if ([fileMgr fileExistsAtPath:docsPath]) {
            if (![fileMgr removeItemAtPath:docsPath
                                     error:&error])
                NSLog(@"Delete directory error: %@", error);
            else
                canCreateDirectory = true;
        }
        else
            canCreateDirectory = true;
        
        BOOL canWriteFile = true;
        
        if (canCreateDirectory) {
            if (![[NSFileManager defaultManager] createDirectoryAtPath:docsPath
                                           withIntermediateDirectories:NO
                                                            attributes:nil
                                                                 error:&error]) {
                NSLog(@"Create directory error: %@", error);
                canWriteFile = false;
            }
        }
        
        if (canWriteFile) {
            NSString* imageId = [media[@"id"] stringByReplacingOccurrencesOfString:@"/" withString:@"^"];
            NSString* imagePath = [NSString stringWithFormat:@"%@/%@.jpg", docsPath, imageId];
            //                NSString* imagePath = [NSString stringWithFormat:@"%@/temp.png", docsPath];
            
            __block NSData* mediaData;
            mediaURL = imagePath;
            
            PHFetchResult* assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[ media[@"id"] ]
                                                                     options:nil];
            if (assets && assets.count > 0) {
                [[PHImageManager defaultManager] requestImageDataForAsset:assets[0]
                                                                  options:options
                                                            resultHandler:^(NSData* _Nullable imageData, NSString* _Nullable dataUTI, UIImageOrientation orientation, NSDictionary* _Nullable info) {
                                                                if (imageData) {
                                                                    //                                                                Processing Image Data if needed
                                                                    if (orientation == UIImageOrientationUp) {
                                                                        mediaData = imageData;
                                                                    }
                                                                    else {
                                                                        UIImage* image = [UIImage imageWithData:imageData];
                                                                        image = [self fixrotation:image];
                                                                        mediaData = UIImageJPEGRepresentation(image, 1);
                                                                    }
                                                                    
                                                                    //writing image to a file
                                                                    NSError* err = nil;
                                                                    if ([mediaData writeToFile:imagePath
                                                                                       options:NSAtomicWrite
                                                                                         error:&err]) {
                                                                        //                                                                    media[@"error"] = @"false";
                                                                    }
                                                                    else {
                                                                        if (err) {
                                                                            //                                                                        media[@"thumbnail"] = @"";
                                                                            NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                        }
                                                                    }
                                                                } else {
                                                                    @autoreleasepool {
                                                                        PHAsset *asset = assets[0];
                                                                        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                                                                                   targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight)
                                                                                                                  contentMode:PHImageContentModeAspectFit
                                                                                                                      options:options
                                                                                                                resultHandler:^(UIImage* _Nullable result, NSDictionary* _Nullable info) {
                                                                                                                    if (result)
                                                                                                                        mediaData =UIImageJPEGRepresentation(result, 1);
                                                                                                                    NSError* err = nil;
                                                                                                                    if ([mediaData writeToFile:imagePath
                                                                                                                                       options:NSAtomicWrite
                                                                                                                                         error:&err]) {
                                                                                                                        //                                                                    media[@"error"] = @"false";
                                                                                                                    }
                                                                                                                    else {
                                                                                                                        if (err) {
                                                                                                                            //                                                                        media[@"thumbnail"] = @"";
                                                                                                                            NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                                                                                        }
                                                                                                                    }
                                                                                                                }];
                                                                    };
                                                                }
                                                            }];

            }
            else {
                if ([media[@"type"] isEqualToString:@"PHAssetCollectionSubtypeAlbumMyPhotoStream"]) {
                    
                    [[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                              subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream
                                                              options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection* collection, NSUInteger idx, BOOL* stop) {
                        if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil) {
                            [[PHAsset fetchAssetsInAssetCollection:collection
                                                           options:nil] enumerateObjectsUsingBlock:^(PHAsset* _Nonnull obj, NSUInteger idx, BOOL* _Nonnull stop) {
                                if ([obj.localIdentifier isEqualToString:media[@"id"]]) {
                                    [[PHImageManager defaultManager] requestImageDataForAsset:obj
                                                                                      options:options
                                                                                resultHandler:^(NSData* _Nullable imageData, NSString* _Nullable dataUTI, UIImageOrientation orientation, NSDictionary* _Nullable info) {
                                                                                    if (imageData) {
                                                                                        //                                                                Processing Image Data if needed
                                                                                        if (orientation == UIImageOrientationUp) {
                                                                                            mediaData = imageData;
                                                                                        }
                                                                                        else {
                                                                                            UIImage* image = [UIImage imageWithData:imageData];
                                                                                            image = [self fixrotation:image];
                                                                                            mediaData = UIImageJPEGRepresentation(image, 1);
                                                                                        }
                                                                                        
                                                                                        //writing image to a file
                                                                                        NSError* err = nil;
                                                                                        if ([mediaData writeToFile:imagePath
                                                                                                           options:NSAtomicWrite
                                                                                                             error:&err]) {
                                                                                            //                                                                    media[@"error"] = @"false";
                                                                                        }
                                                                                        else {
                                                                                            if (err) {
                                                                                                //                                                                        media[@"thumbnail"] = @"";
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
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:mediaURL ? CDVCommandStatus_OK : CDVCommandStatus_ERROR
                                                          messageAsString:mediaURL];
        
        [self.commandDelegate sendPluginResult:pluginResult
                                    callbackId:command.callbackId];
    }];
}

+ (NSDictionary*)subtypes
{
    NSDictionary* subtypes = @{ @(PHAssetCollectionSubtypeAlbumRegular) : @"PHAssetCollectionSubtypeAlbumRegular",
                                @(PHAssetCollectionSubtypeAlbumImported) : @"PHAssetCollectionSubtypeAlbumImported",
                                @(PHAssetCollectionSubtypeAlbumMyPhotoStream) : @"PHAssetCollectionSubtypeAlbumMyPhotoStream",
                                @(PHAssetCollectionSubtypeAlbumCloudShared) : @"PHAssetCollectionSubtypeAlbumCloudShared",
                                @(PHAssetCollectionSubtypeSmartAlbumFavorites) : @"PHAssetCollectionSubtypeSmartAlbumFavorites",
                                @(PHAssetCollectionSubtypeSmartAlbumRecentlyAdded) : @"PHAssetCollectionSubtypeSmartAlbumRecentlyAdded",
                                @(PHAssetCollectionSubtypeSmartAlbumUserLibrary) : @"PHAssetCollectionSubtypeSmartAlbumUserLibrary",
                                @(PHAssetCollectionSubtypeSmartAlbumSelfPortraits) : @"PHAssetCollectionSubtypeSmartAlbumSelfPortraits",
                                @(PHAssetCollectionSubtypeSmartAlbumScreenshots) : @"PHAssetCollectionSubtypeSmartAlbumScreenshots",
                                };
    return subtypes;
}

- (UIImage*)fixrotation:(UIImage*)image
{
    
    if (image.imageOrientation == UIImageOrientationUp)
        return image;
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage* img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

+ (NSString*)cordovaVersion
{
    return CDV_VERSION;
}

@end
