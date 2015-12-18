//
//  TagsController.swift
//  Dazar
//
//  Created by Alex Shacked on 19/11/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

protocol TagsControllerDelegate: class {
    func tagsControllerDidCancel(controller: TagsController)
    func tagsController(controller: TagsController, didFinishSelectingTags tags: [String])
}

class TagsController: UITableViewController {
    var items: [TagItem]
    weak var delegate: TagsControllerDelegate?
    var utils = Utils()
    
    @IBAction func cancel() {
        print("tags cancel")
        delegate?.tagsControllerDidCancel(self)
    }
    
    @IBAction func done() {
        print("tags done")
        var tags = [String]()
        for item in items {
            if item.checked {
                tags.append(item.text)
            }
        }
        
        if tags.isEmpty == true {
            utils.displayAlertWithTitle(self, title: "No tags chosen", message: "Need to select at least one tag for your vendors search")
        } else {
            delegate?.tagsController(self, didFinishSelectingTags: tags)
        }
    }
    
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
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier( "CategoryItem", forIndexPath: indexPath)
        let item = items[indexPath.row]
        
        cellLabel(cell, item: item)
        cellCheck(cell, item: item)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            let item = items[indexPath.row]
            item.toggle()
            cellCheck(cell, item: item)
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func cellLabel(cell: UITableViewCell, item: TagItem) {
        let label = cell.viewWithTag(1000) as! UILabel
        label.text = item.text
    }
    
    func cellCheck(cell: UITableViewCell, item: TagItem) {
        if item.checked {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
    }
}






