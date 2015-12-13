//
//  MyVendorsController.swift
//  Dazar
//
//  Created by Alex Shacked on 12/12/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

protocol MyVendorsControllerDelegate: class {
    func myVendorControllerDidCancel(controller: MyVendorsController)
    func myVendorControllerDidOk(controller: MyVendorsController, didFinishSelectingVendor vendor: String)
}

class VendorItem {
    var text: String
    var checked: Bool
    
    init(text: String, checked: Bool) {
        self.text = text
        self.checked = checked
    }
    
    func toggle() {
        checked = !checked
    }
}


class MyVendorsController: UITableViewController {
    var items: [VendorItem] = []
    weak var delegate: MyVendorsControllerDelegate?
    
    @IBAction func done(sender: AnyObject) {
        print("my vendors done")
        var selected = ""
        for item in items {
            if item.checked == true {
                selected = item.text
            }
        }
        delegate?.myVendorControllerDidOk(self, didFinishSelectingVendor: selected)
    }
    
    @IBAction func cancel(sender: AnyObject) {
        print("my vendors cancel")
        delegate?.myVendorControllerDidCancel(self)
    }
    
    func setItems(items: [VendorItem]) {
        self.items = items
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if items.isEmpty == true  {
            return 1
        }
        return items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier( "VendorItem", forIndexPath: indexPath)
        if items.isEmpty == true {
            return cellNoVendors(cell)
        }
        
        let item = items[indexPath.row]
        cellLabel(cell, item: item)
        cellCheck(cell, item: item)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if items.isEmpty {
            return
        }
        
        let item = items[indexPath.row]
        if item.checked == true { // we must select an unchecked vendor in order to change current vendor
            return
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        item.toggle()
        cellCheck(cell!, item: item)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
                
        // deselect previous
        for var i = 0; i < items.count; i++ {
            if items[i].checked == false  || i == indexPath.row {
                continue
            }
                
            let idxPath = NSIndexPath(forRow: i, inSection: indexPath.section)
            var cell = tableView.cellForRowAtIndexPath(idxPath)
            items[i].toggle()
            cellCheck(cell!, item: items[i])
            tableView.deselectRowAtIndexPath(idxPath, animated: true)
            break
        }
    }
    
    func cellNoVendors(cell: UITableViewCell) -> UITableViewCell {
        let label = cell.viewWithTag(1001) as! UILabel
        label.text = "NO VENDORS YET";
        return cell
    }
    
    func cellLabel(cell: UITableViewCell, item: VendorItem) {
        let label = cell.viewWithTag(1001) as! UILabel
        label.text = item.text
    }
    
    func cellCheck(cell: UITableViewCell, item: VendorItem) {
        if item.checked {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
    }
}