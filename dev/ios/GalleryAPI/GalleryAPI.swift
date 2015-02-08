//
//  GalleryAPI.swift
//  GalleryAPI
//
//  Created by Thomas Decaux on 08/02/2015.
//  Copyright (c) 2015 SubitoLabs. All rights reserved.
//

import Foundation
import AssetsLibrary

class GalleryAPI
{
    func getAlbums() -> NSArray
    {
        var albums : NSMutableArray = NSMutableArray()
        var library = ALAssetsLibrary()
        
        library.enumerateGroupsWithTypes(ALAssetsGroupAll, usingBlock: { (group, stop) -> Void in
           
            var title : NSString = group.valueForProperty(ALAssetsGroupPropertyName) as String
            
            albums.addObject(["title" : title])
            
            }) { (error) -> Void in
                println("problem loading albums: \(error)")
        }
        
        return albums
    }
    
    func getMedia(album : NSString)
    {
        
    }
}