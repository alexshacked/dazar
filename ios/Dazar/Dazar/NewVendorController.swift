//
//  NewVendorController.swift
//  Dazar
//
//  Created by Alex Shacked on 28/11/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit


protocol NewVendorControllerDelegate: class {
    func newVendorControllerDidCancel(controller: NewVendorController)
    func newVendorControllerDidOk(controller: NewVendorController, newVendorRequest request: [NSString: AnyObject])
}

class NewVendorController: UITableViewController, UITextFieldDelegate {
    weak var delegate: NewVendorControllerDelegate?
    var utils = Utils()
    
    @IBOutlet weak var country: UITextField!
    @IBOutlet weak var city: UITextField!
    @IBOutlet weak var streetName: UITextField!
    @IBOutlet weak var houseNumber: UITextField!
    @IBOutlet weak var phoneNumber: UITextField!
    @IBOutlet weak var businessName: UITextField!
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
            return //super.tableView(tableView, didSelectRowAtIndexPath: indexPath)
        }
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let item = items[indexPath.row]
            item.toggle()
            cellCheck(cell, item: item)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section != 2 {
            return nil
        }
        return indexPath
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
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
        delegate?.newVendorControllerDidCancel(self)
    }
    
    @IBAction func done() {
        print("location done")
        
        var tags = [String]()
        for item in items {
            if item.checked {
                tags.append(item.text)
            }
        }
    
        if tags.isEmpty || validateTextInput() == false {
            utils.displayAlertWithTitle(self, title: "Input data missing",
                message: "Must provide business name, phone, full address and at least one category for the business market.")
        }
        else {
           var fullAddress = houseNumber.text! + " " + streetName.text! + ", " + city.text!
            if country.text?.isEmpty == false {
                fullAddress = fullAddress + ", " + country.text!
            }
            let request : [NSString: AnyObject] =
            [
                "vendor": businessName.text!,
                "address": fullAddress,
                "phone": phoneNumber.text!,
                "tags": tags
            ]

            delegate?.newVendorControllerDidOk(self, newVendorRequest: request)
        }
    }
    
    func validateTextInput() -> Bool {
        if businessName.text?.isEmpty == true || phoneNumber.text?.isEmpty == true ||
           houseNumber.text?.isEmpty == true || streetName.text?.isEmpty == true ||
           city.text?.isEmpty  == true || country.text?.isEmpty == true {
            return false
        }
        
        return true
    }

    override func viewDidLoad() {
        country.delegate = self
        city.delegate = self
        streetName.delegate = self
        houseNumber.delegate = self
        phoneNumber.delegate = self
        businessName.delegate = self
        
        super.viewDidLoad()
        
    }
}
