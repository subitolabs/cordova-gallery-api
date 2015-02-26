//
//  GalleryAPI.h
//  galleryapi
//
//  Created by Thomas Decaux on 26/02/2015.
//  Copyright (c) 2015 SubitoLabs. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>

@interface GalleryAPI : NSObject

- (void) getAlbums:(void (^) (NSArray *))successHandler withErrorHandler:(void (^) (NSString *))errorHandler;

- (void) getAlbumAssets:(NSString*) album withSuccessHandler:(void (^) (NSArray *))successHandler andErrorHandler:(void (^) (NSString *))errorHandler;

@end