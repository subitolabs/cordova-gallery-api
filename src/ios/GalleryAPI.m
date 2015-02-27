#import <Cordova/CDV.h>

#import "GalleryAPI.h"

@interface GalleryAPI ()

@end

@implementation GalleryAPI

- (void) getAlbums:(CDVInvokedUrlCommand*)command
{
    __block ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    __block NSMutableArray *albums = [[NSMutableArray alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         if (group == nil)
         {
             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:albums];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
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
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     }];
}

- (void) getMedia:(CDVInvokedUrlCommand*)command
{
    NSString *album = [command argumentAtIndex:0];
    __block ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    __block NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop)
     {
         if (group == nil)
         {
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:assets];

            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
         }
         else
         {
             if ([album isEqualToString:[group valueForProperty:ALAssetsGroupPropertyName]])
             {
                 [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:
                  ^(ALAsset *result, NSUInteger index, BOOL *stop)
                  {
                      if(result == nil)
                      {
                            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:assets];

                            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
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
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:error.localizedDescription];

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

+ (NSString*)cordovaVersion
{
    return CDV_VERSION;
}

@end
