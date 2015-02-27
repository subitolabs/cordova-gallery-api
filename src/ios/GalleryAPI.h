#import <AssetsLibrary/AssetsLibrary.h>
#import <AssetsLibrary/ALAssetsGroup.h>
#import <Cordova/CDVPlugin.h>

@interface GalleryAPI : CDVPlugin

- (void) getAlbums:(CDVInvokedUrlCommand*)command;

- (void) getMedia:(CDVInvokedUrlCommand*)command;

@end
