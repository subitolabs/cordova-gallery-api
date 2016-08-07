#import <Cordova/CDV.h>
#import "CDVFile.h"

#import "GalleryAPI.h"

@interface GalleryAPI ()

@end

@implementation GalleryAPI

- (void) getAlbums:(CDVInvokedUrlCommand*)command
{
    __block NSMutableArray *albums = [[NSMutableArray alloc] init];
    NSArray *collectionTypes = @[
                                 @{@"title" : @"smart", @"type" : [NSNumber numberWithInteger: PHAssetCollectionTypeSmartAlbum]},
                                 @{@"title" : @"album", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum]}
                                 ];
    
    for (NSDictionary *collectionType in collectionTypes)
    {
        [[PHAssetCollection fetchAssetCollectionsWithType:[[collectionType objectForKey:@"type"] integerValue] subtype:PHAssetCollectionSubtypeAny options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
         {
             if (collection != nil && collection.localizedTitle != nil && collection.localIdentifier != nil)
             {
                 if (collection.estimatedAssetCount > 0) {
                     [albums addObject:@{
                                         @"id" : collection.localIdentifier,
                                         @"title" : collection.localizedTitle,
                                         @"type" : [collectionType objectForKey:@"title"],
                                         @"assets" : [NSString stringWithFormat:@"%ld", (long) collection.estimatedAssetCount]
                                         }];
                 }
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
                                 @{@"title" : @"album", @"type" : [NSNumber numberWithInteger:PHAssetCollectionTypeAlbum]}
                                 ];
    
    for (NSDictionary *collectionType in collectionTypes)
    {
        [[PHAssetCollection fetchAssetCollectionsWithType:[[collectionType objectForKey:@"type"] integerValue]
                                                  subtype:PHAssetCollectionSubtypeAny
                                                  options:nil] enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop)
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
                           NSString *imageName = @"";
                           NSString *originalImagePath = @"";
                           
                           if ([info objectForKey:@"PHImageFileUTIKey"])
                               imageName = [info objectForKey:@"PHImageFileUTIKey"];
                           
                           if ([info objectForKey:@"PHImageFileURLKey"]){
                               originalImagePath = [[info objectForKey:@"PHImageFileURLKey"] absoluteString];
                           }
                           
                           [assets addObject:@{
                                               @"id" : obj.localIdentifier,
                                               @"title" : imageName,
                                               @"orientation" : @"up",
                                               @"lat" : @4,
                                               @"lng" : @5,
                                               @"width" : [NSNumber numberWithFloat:obj.pixelWidth],
                                               @"height" : [NSNumber numberWithFloat:obj.pixelHeight],
                                               @"size" : @0,
                                               @"data" : originalImagePath,
                                               @"thumbnail" : @"",
                                               @"thumbnailLoaded" : @(false)
                                               }];
                           
                       }];
                  }];
             }
         }];
    }
    
    NSArray* reversedAssests = [[assets reverseObjectEnumerator] allObjects];
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:reversedAssests];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getMediaThumbnail:(CDVInvokedUrlCommand*)command {
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
        
        PHFetchResult *assets = [PHAsset fetchAssetsWithLocalIdentifiers:@[media[@"id"]]
                                                                 options:nil];
        [[PHImageManager defaultManager] requestImageDataForAsset:assets[0]
                                                          options:nil
                                                    resultHandler:^(NSData * _Nullable imageData,
                                                                    NSString * _Nullable dataUTI,
                                                                    UIImageOrientation orientation,
                                                                    NSDictionary * _Nullable info) {
                                                        UIImage* originalImage = [UIImage imageWithData:imageData];
                                                        UIImage* thumbnailImage = [GalleryAPI resizedImage:originalImage ToSize:CGSizeMake(300, 300)];
                                                        NSError* err = nil;
                                                        if (![UIImagePNGRepresentation(thumbnailImage) writeToFile:thumbnailPath
                                                                                                           options:NSAtomicWrite
                                                                                                             error:&err])
                                                        {
                                                            if (err)
                                                            {
                                                                media[@"thumbnail"] = @"";
                                                                NSLog(@"Error saving image: %@", [err localizedDescription]);
                                                            }
                                                        }}];
        
        
    }
    
    media[@"thumbnailLoaded"] = @(true);
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                  messageAsDictionary:media];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

+(UIImage*)resizedImage:(UIImage *) image  ToSize:(CGSize)dstSize
{
    CGImageRef imgRef = image.CGImage;
    // the below values are regardless of orientation : for UIImages from Camera, width>height (landscape)
    CGSize  srcSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef)); // not equivalent to self.size (which is dependant on the imageOrientation)!
    
    /* Don't resize if we already meet the required destination size. */
    if (CGSizeEqualToSize(srcSize, dstSize)) {
        return image;
    }
    
    CGFloat scaleRatio = dstSize.width / srcSize.width;
    UIImageOrientation orient = image.imageOrientation;
    CGAffineTransform transform = CGAffineTransformIdentity;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(srcSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(srcSize.width, srcSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, srcSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeTranslation(srcSize.height, srcSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI_2);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeTranslation(0.0, srcSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI_2);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            dstSize = CGSizeMake(dstSize.height, dstSize.width);
            transform = CGAffineTransformMakeTranslation(srcSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    /////////////////////////////////////////////////////////////////////////////
    // The actual resize: draw the image on a new context, applying a transform matrix
    UIGraphicsBeginImageContextWithOptions(dstSize, NO,image.scale);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (!context) {
        return nil;
    }
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -srcSize.height, 0);
    } else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -srcSize.height);
    }
    
    CGContextConcatCTM(context, transform);
    
    // we use srcSize (and not dstSize) as the size to specify is in user space (and we use the CTM to apply a scaleRatio)
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, srcSize.width, srcSize.height), imgRef);
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

+ (NSString*)cordovaVersion
{
    return CDV_VERSION;
}

@end
