//
//  LocationController.swift
//  Dazar
//
//  Created by Alex Shacked on 19/11/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

protocol LocationControllerDelegate: class {
    func locationControllerDidCancel(controller: LocationController)
    func locationController(controller: LocationController, didFinishSelectingLocation location: String)
}


class LocationController: UITableViewController {
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet var streetNo: UITextField!
    @IBOutlet var streetName: UITextField!
    @IBOutlet var city: UITextField!
    @IBOutlet var country: UITextField!
    
    var startAddress: String = ""
    
    weak var delegate: LocationControllerDelegate?
    
    func setSearchLocation(startLocation: String) {
        startAddress = startLocation
    }
    
    @IBAction func OnSwitchValueChanged(sender: AnyObject) {
        let sw: UISwitch = sender as! UISwitch
        if sw.on {
            print("switch on")
            clearAddresControls()
            enableAddress(false)
        } else {
            print("switch off")
            enableAddress(true)
        }
    }
    
    @IBAction func cancel() {
        print("location cancel")
        delegate?.locationControllerDidCancel(self)
    }
    
    @IBAction func done() {
        print("location done")
        var address: String = ""
        if streetNo.enabled { // this means we are browsing at some arbitrary location - not the device's
            if (streetNo.text?.isEmpty == true  || streetName.text?.isEmpty == true  || city.text?.isEmpty == true)  {
                //leave here - you need at least these for an address
                address = ""
            } else {
                address.appendContentsOf(streetNo.text!)
                address.appendContentsOf(" ")
                address.appendContentsOf(streetName.text!)
                address.appendContentsOf(", ")
                address.appendContentsOf(city.text!)
                if country.text?.isEmpty == false {
                    address.appendContentsOf(", ")
                    address.appendContentsOf(country.text!)
                }
            }
    
        }
        delegate?.locationController(self, didFinishSelectingLocation: address)
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
    
    func enableAddress(enable: Bool) {
        streetNo.enabled = enable
        streetName.enabled = enable
        city.enabled = enable
        country.enabled = enable
    }
    
    func clearAddresControls() {
        streetNo.text = ""
        streetName.text = ""
        city.text = ""
        country.text = ""
    }
    
    func setAddressControls(startAddress: String) {
        let toks = startAddress.componentsSeparatedByString(",")
        let streetAddr = toks[0]
        let city = toks[1]
        var country: String = ""
        if toks.count == 3 {
            country = toks[2]
        }
        let streetToks = streetAddr.componentsSeparatedByString(" ")
        let streetNo = streetToks[0]
        var streetName = streetToks[1]
        for var i = 2; i < streetToks.count; ++i { // in case street name is made from more than one word - Bnei Ephraim
            streetName.appendContentsOf(" ")
            streetName.appendContentsOf(streetToks[i])
        }
        
        self.streetNo.text = streetNo.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        self.streetName.text = streetName.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        self.city.text = city.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        self.country.text = country.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if startAddress.isEmpty {
            locationSwitch.setOn(true, animated: true)
            enableAddress(false)
        } else {
            locationSwitch.setOn(false, animated: true)
            enableAddress(true)
            setAddressControls(startAddress)
        }
    }
}



