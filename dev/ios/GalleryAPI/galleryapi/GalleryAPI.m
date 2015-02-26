//
//  GalleryAPI.m
//  galleryapi
//
//  Created by Thomas Decaux on 26/02/2015.
//  Copyright (c) 2015 SubitoLabs. All rights reserved.
//

#import "GalleryAPI.h"

@interface GalleryAPI ()

@end

@implementation GalleryAPI

- (void) getAlbums:(void (^) (NSArray *))successHandler withErrorHandler:(void (^) (NSString *))errorHandler
{
    __block ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    __block NSMutableArray *albums = [[NSMutableArray alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         if (group == nil)
         {
             successHandler(albums);
         }
         else
         {
             [albums addObject:@{
                                 @"id" : [group valueForProperty:ALAssetsGroupPropertyPersistentID],
                                 @"title" : [group valueForProperty:ALAssetsGroupPropertyName],
                                 @"assets" : [NSString stringWithFormat:@"%ld", group.numberOfAssets]
                                 }];
         }
         
     }
     failureBlock: ^(NSError *error)
    {
        errorHandler(error.localizedDescription);
     }];
}

- (void) getAlbumAssets:(NSString*) album withSuccessHandler:(void (^) (NSArray *))successHandler andErrorHandler:(void (^)(NSString *))errorHandler
{
    __block ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    __block NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         if (group == nil)
         {
             successHandler(assets);
         }
         else
         {
             if (album == [group valueForProperty:ALAssetsGroupPropertyName])
             {
                 [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:
                  ^(ALAsset *result, NSUInteger index, BOOL *stop)
                  {
                      if(result == nil)
                      {
                          successHandler(assets);
                      }
                      else
                      {
                          ALAssetRepresentation *representation = result.defaultRepresentation;
                          CGSize dimensions = representation.dimensions;
                        
                          
                          [assets addObject:@{
                                              @"id" : [[result valueForProperty:ALAssetPropertyAssetURL] absoluteString],
                                              @"title" : representation.filename,
                                              @"orientation" : @"up",
                                              @"lat" : @4,
                                              @"lng" : @5,
                                              @"width" : [NSNumber numberWithFloat:dimensions.width],
                                              @"height" : [NSNumber numberWithFloat:dimensions.height],
                                              @"size" : [NSNumber numberWithLongLong:representation.size],
                                              @"data" : representation.url.absoluteString,
                                              @"thumbnail" : representation.url.absoluteString
                          }];
                      }
                  }
                  ];
             }
             
         }
     }
     failureBlock: ^(NSError *error)
    {
         errorHandler(error.localizedDescription);
    }];
}

@end