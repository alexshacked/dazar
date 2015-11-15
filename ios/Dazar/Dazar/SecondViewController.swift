import UIKit

class SecondViewController: UIViewController {
    @IBOutlet var latitudeTextField : UITextField!
    @IBOutlet var longitudeTextField : UITextField!
    @IBOutlet var resultsTextView : UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        latitudeTextField.text = "32.7852402"
        longitudeTextField.text = "34.9879514"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func calculateTapped(sender : AnyObject)  {
        let lat = latitudeTextField.text!
        let lng = longitudeTextField.text!
        do {
            try doGetTweets(lat, longitude: lng)
        } catch {
            
        }
        
    }
    @IBAction func viewTapped(sender : AnyObject) {
        latitudeTextField.resignFirstResponder()
        longitudeTextField.resignFirstResponder()
    }
    
    func doGetTweets(latitude: String, longitude: String) throws {
        let httpMethod = "POST"
        let timeout = 15.0
        let urlAsString = "http://dazar.io/getTweets"
        let url = NSURL(string: urlAsString)
        
        let urlRequest = NSMutableURLRequest(URL: url!,
            cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: timeout)
        urlRequest.HTTPMethod = httpMethod
        
        let request : [NSString: AnyObject] =
        [
            "latitude": latitude,
            "longitude": longitude,
            "radius": "5000",
            "tags": [String]()
        ]
        
        
        let jsonData = try NSJSONSerialization.dataWithJSONObject(request,
            options: .PrettyPrinted)
        let body = NSString(data: jsonData, encoding: NSUTF8StringEncoding)
        
        urlRequest.HTTPBody = body?.dataUsingEncoding(NSUTF8StringEncoding)
        
        let response: AutoreleasingUnsafeMutablePointer<NSURLResponse?>=nil
        let dataVal: NSData =  try NSURLConnection.sendSynchronousRequest(urlRequest, returningResponse: response)
        print(response)
        let jsonResult: NSDictionary = (try NSJSONSerialization.JSONObjectWithData(dataVal, options: NSJSONReadingOptions.MutableContainers) as? NSDictionary)!
        print("Synchronous\(jsonResult)")
        self.resultsTextView.text = String(jsonResult)
    }

}

