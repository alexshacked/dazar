//
//  Utils.swift
//  Dazar
//
//  Created by Alex Shacked on 18/12/2015.
//  Copyright © 2015 Dazar. All rights reserved.
//

import UIKit

class Utils {
    func rest(command: String, request : [NSString: AnyObject]) throws -> NSDictionary {
        let httpMethod = "POST"
        let timeout = 15.0
        let urlAsString = "http://dazar.io/" + command
        let url = NSURL(string: urlAsString)
        
        let urlRequest = NSMutableURLRequest(URL: url!,
            cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: timeout)
        urlRequest.HTTPMethod = httpMethod
        
        let jsonData = try NSJSONSerialization.dataWithJSONObject(request,
            options: .PrettyPrinted)
        let body = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
        
        urlRequest.HTTPBody = body?.dataUsingEncoding(NSUTF8StringEncoding)
        
        let response: AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
        let dataVal: NSData =  try NSURLConnection.sendSynchronousRequest(urlRequest, returningResponse: response)
        print(command)
        print(response)
        let jsonResult: NSDictionary = (try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary)!
        print("Synchronous\(jsonResult)")
        
        return jsonResult
    }
    
    func displayAlertWithTitle(father: UIViewController, title: String, message: String){
        let controller = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(title: "OK",
            style: .Default,
            handler: nil))
        
        father.presentViewController(controller, animated: true, completion: nil)
    }
}
