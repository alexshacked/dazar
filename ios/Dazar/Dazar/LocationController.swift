//
//  LocationController.swift
//  Dazar
//
//  Created by Alex Shacked on 19/11/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

class LocationController: UITableViewController {
    @IBAction func cancel() {
        print("location cancel")
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func done() {
        print("location done")
        dismissViewControllerAnimated(true, completion: nil)
    }
}
