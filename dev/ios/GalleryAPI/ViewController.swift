//
//  ViewController.swift
//  GalleryAPI
//
//  Created by Thomas Decaux on 08/02/2015.
//  Copyright (c) 2015 SubitoLabs. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var api = GalleryAPI()
        
        api.getAlbums()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

