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

- (void) getAlbums:(void (^) (NSArray *))successHandler
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
                                 @"title" : [group valueForProperty:ALAssetsGroupPropertyName],
                                 @"assets" : [NSString stringWithFormat:@"%ld", group.numberOfAssets]
                                 }];
         }
         
     } failureBlock: ^(NSError *error) {
         // Typically you should handle an error more gracefully than this.
         NSLog(@"No groups");
     }];
}

- (void) getAlbumAssets:(NSString*) album withSuccessHandler:(void (^) (NSArray *))successHandler
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
                          
                          [assets addObject:@{
                                              @"title" : representation.filename,
                                              }];
                          
                      }
                  }
                  ];
             }
             
         }
     }
                         failureBlock: ^(NSError *error) {
                             // Typically you should handle an error more gracefully than this.
                             NSLog(@"No groups");
                         }];
}

@end