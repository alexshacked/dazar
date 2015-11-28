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
    
    var items: [TagItem]
    //weak var delegate: LocationControllerDelegate?
    
    required init(coder aDecoder: NSCoder) {
        items = [TagItem]()
        items.append(TagItem(text: Tag.Restaurants.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Cafes.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Clothing.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Shoes.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Electronix.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Beauty.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Home.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Grocery.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Kids.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Media.simpleDescription(), checked: false))
        items.append(TagItem(text: Tag.Sports.simpleDescription(), checked: false))
        
        super.init(coder: aDecoder)!
    }
    
    func resetTags(arr: [String]) {
        if arr[0] == "all" {
            for item in items {
                item.checked = true
            }
        } else {
            for a in arr {
                for item in items {
                    if a == item.text {
                        item.checked = true
                    }
                }
                
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != 2 {
            return super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let item = items[indexPath.row]
            item.toggle()
            cellCheck(cell, item: item)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func cellCheck(cell: UITableViewCell, item: TagItem) {
        if item.checked {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
    }
    
    @IBAction func cancel() {
        print("new vendor cancel")
        dismissViewControllerAnimated(true, completion: nil)
        //delegate?.locationControllerDidCancel(self)
    }
    
    @IBAction func done() {
        print("location done")
        
        var tags = [String]()
        for item in items {
            if item.checked {
                tags.append(item.text)
            }
        }
        if tags.isEmpty {
            displayAlertWithTitle("Input data missing",
                message: "Must provide business name, phone, full address and at least one category for the business market.")
        }
        else {
            dismissViewControllerAnimated(true, completion: nil)
        }
        // delegate?.locationController(self, didFinishSelectingLocation: address)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func displayAlertWithTitle(title: String, message: String){
        let controller = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK",
            style: .Default,
            handler: nil)
        controller.addAction(action)
        
        presentViewController(controller, animated: true, completion: nil)
    }

}
