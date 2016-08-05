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
                           
                           if ([info objectForKey:@"PHImageFileUTIKey"])
                           {
                               filename = [info objectForKey:@"PHImageFileUTIKey"];
                           }
                           
                           UIImage* originalImage = [UIImage imageWithData:imageData];
                           UIImage* thumbnailImage = [GalleryAPI resizedImage:originalImage ToSize:CGSizeMake(300, 300)];
                           
                           NSString* docsPath = [NSTemporaryDirectory() stringByStandardizingPath]; // use file system temporary directory
                           NSString* filePath = [NSString stringWithFormat:@"%@/%@.png", docsPath, [obj.localIdentifier stringByReplacingOccurrencesOfString:@"/" withString:@"^"]];
                           
                           NSFileManager* fileMgr = [[NSFileManager alloc] init];
                           
                           if (![fileMgr fileExistsAtPath:filePath]) {
                               NSLog(@"file doesn't exist");
                               NSError* err = nil;
                               if (![UIImagePNGRepresentation(thumbnailImage) writeToFile:filePath
                                                                                  options:NSAtomicWrite
                                                                                    error:&err]) {
                                   if (err)
                                       NSLog(@"Error saving image: %@", [err localizedDescription]);
                               }
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
                                               @"data" : filePath,
                                               @"thumbnail" : filePath
                                               }];
                           
                       }];
                  }];
             }
         }];
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:assets];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getMediaThumbnail:(CDVInvokedUrlCommand*)command {
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:[NSArray new]];
    
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

+ (UIImage *)imageWithImage:(UIImage *)image scaledToFillSize:(CGSize)size
{
    CGFloat scale = MAX(size.width/image.size.width, size.height/image.size.height);
    CGFloat width = image.size.width * scale;
    CGFloat height = image.size.height * scale;
    CGRect imageRect = CGRectMake((size.width - width)/2.0f,
                                  (size.height - height)/2.0f,
                                  width,
                                  height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:imageRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
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
