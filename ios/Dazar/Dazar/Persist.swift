//
//  Persist.swift
//  Dazar
//
//  Created by Alex Shacked on 13/12/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

class Persist {
    var fullPath: String!
    
    init(file: String) {
        fullPath = dataFilePath(file)
        print("full path is:   \(fullPath)")
    }
    
    func documentsDirectory() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(
        .DocumentDirectory, .UserDomainMask, true)
        return paths[0]
    }
    
    func dataFilePath(file: String) -> String {
        return (documentsDirectory() as NSString)
            .stringByAppendingPathComponent(file)
    }
    
    func saveAllVendors(items: [String:VendorData], vendorId: String) {
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWithMutableData: data)
        archiver.encodeObject(items, forKey: "allVendors")
        archiver.encodeObject(vendorId, forKey: "vendorId")
        archiver.finishEncoding()
        data.writeToFile(fullPath, atomically: true)
    }
    
    func loadAllVendors() -> [String:VendorData]! {
        // 1
        var items: [String:VendorData]!
        let path = fullPath!
        // 2
        if NSFileManager.defaultManager().fileExistsAtPath(path) {
            // 3
            let data = NSData(contentsOfFile: path)
            let unarchiver = NSKeyedUnarchiver(forReadingWithData: data!)
            items = unarchiver.decodeObjectForKey("allVendors") as! [String:VendorData]
            unarchiver.finishDecoding()
        }
        return items!
    }
    
    func loadVendorId() -> String! {
        var vendorId:String!
                
        if NSFileManager.defaultManager().fileExistsAtPath(fullPath) {
            let data = NSData(contentsOfFile: fullPath)
            let unarchiver = NSKeyedUnarchiver(forReadingWithData: data!)
            vendorId = unarchiver.decodeObjectForKey("vendorId") as! String
            unarchiver.finishDecoding()
        }
                
        return vendorId
    }
}








