//
//  NewVendorController.swift
//  Dazar
//
//  Created by Alex Shacked on 28/11/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

/*
protocol LocationControllerDelegate: class {
    func locationControllerDidCancel(controller: LocationController)
    func locationController(controller: LocationController, didFinishSelectingLocation location: String)
}
*/

class NewVendorController: UITableViewController {
    
    //weak var delegate: LocationControllerDelegate?
    
    @IBAction func cancel() {
        print("new vendor cancel")
        dismissViewControllerAnimated(true, completion: nil)
        //delegate?.locationControllerDidCancel(self)
    }
    
    @IBAction func done() {
        print("location done")
        dismissViewControllerAnimated(true, completion: nil)
        // delegate?.locationController(self, didFinishSelectingLocation: address)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
