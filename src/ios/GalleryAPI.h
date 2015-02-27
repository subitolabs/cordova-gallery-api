#import <AssetsLibrary/AssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>
#import <Cordova/CDVPlugin.h>

@interface GalleryAPI : NSObject

- (void) getAlbums:(void (^) (NSArray *))successHandler withErrorHandler:(void (^) (NSString *))errorHandler;

- (void) getAlbumAssets:(NSString*) album withSuccessHandler:(void (^) (NSArray *))successHandler andErrorHandler:(void (^) (NSString *))errorHandler;

@end
