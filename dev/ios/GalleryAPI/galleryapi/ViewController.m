//
//  ViewController.m
//  galleryapi
//
//  Created by Thomas Decaux on 26/02/2015.
//  Copyright (c) 2015 SubitoLabs. All rights reserved.
//

#import "ViewController.h"

#import "GalleryAPI.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    GalleryAPI *api = [GalleryAPI alloc];
    
    [api getAlbums:^(NSArray *albums)
    {
        for (NSDictionary *album in albums)
        {
            NSLog(@"-> Album %@", [album objectForKey:@"title"]);
            
            [api getAlbumAssets:[album objectForKey:@"title"] withSuccessHandler:^(NSArray *assets)
             {
                 for (NSDictionary *asset in assets)
                 {
                     NSLog(@"----> Asset %@ %@", [asset objectForKey:@"title"], [asset objectForKey:@"thumbnail"]);
                 }
             }
             andErrorHandler:^(NSString *error)
             {
                 NSLog(@"<!> ERROR: %@ <!>", error);
             }];
        }
        
    }
     withErrorHandler:^(NSString *error)
     {
         NSLog(@"<!> ERROR: %@ <!>", error);
     }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
