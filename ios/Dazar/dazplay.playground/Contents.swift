//: Playground - noun: a place where people can play

import UIKit

var n = 6
var str: String = "Hello dazplay"

let latitude = "23.5678"
let longitude = "48.789"
var request : [NSString: AnyObject] =
[
    "latitude": latitude,
    "longitude": longitude,
    "radius": "20000",
    "tags": ["restaurants"]
]


let jsonData = try NSJSONSerialization.dataWithJSONObject(request,
    options: .PrettyPrinted)
let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding)






