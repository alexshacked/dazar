import UIKit
import CoreLocation
import MapKit

class VendorData: NSObject, NSCoding {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var tags: [String]
    
    required init?(coder aDecoder: NSCoder) {
        name = aDecoder.decodeObjectForKey("name") as! String
        address = aDecoder.decodeObjectForKey("address") as! String
        latitude = aDecoder.decodeDoubleForKey("latitude")
        longitude = aDecoder.decodeDoubleForKey("longitude")
        tags = aDecoder.decodeObjectForKey("tags") as! [String]
        super.init()
    }
    
    init(name: String, address: String, latitude: Double, longitude: Double, tags: [String]) {
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.tags = tags
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(name, forKey: "name")
        aCoder.encodeObject(address, forKey: "address")
        aCoder.encodeDouble(latitude, forKey: "latitude")
        aCoder.encodeDouble(longitude, forKey: "longitude")
        aCoder.encodeObject(tags, forKey: "tags")
    }
}

class SecondViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate,
            NewVendorControllerDelegate,  MyVendorsControllerDelegate, TweetControllerDelegate {
    
    @IBOutlet weak var buttonTweet: UIBarButtonItem!
    @IBOutlet weak var buttonSilent: UIBarButtonItem!
    @IBOutlet weak var buttonVendors: UIBarButtonItem!
    var locationManager: CLLocationManager?
    var mapView: MKMapView!
    var startTime: CFAbsoluteTime! = nil
    var tag = 1
    var searchTags: [String] = ["all"]
    
    var vendorId: String = ""
    var allVendors = [String:VendorData]()
    var persist: Persist!
    var utils = Utils()
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        mapView = MKMapView()
        persist = Persist(file: "vendors.plist")
        allVendors = persist.loadAllVendors()
        vendorId = persist.loadVendorId()
        validateVendors()
    }
    
    /* We have a pin on the map; now zoom into it and make that pin
    the center of the map */
    func setCenterOfMapToLocation(location: CLLocationCoordinate2D){
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func getTime() -> String {
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = .LongStyle
        let res = formatter.stringFromDate(date)
        return res
    }
    
    func addPinToMapView(lat: Double, lng: Double, an: AnType, title: String, subtitle: String,
        tweet: String, tags: [String]?) {
        //print("addPinToMapView() called: \(getTime())")
            
        /* The locations */
        let locCustomer = CLLocationCoordinate2D(latitude: lat,
            longitude: lng)
        
        /* Create the annotation using the location */
        let vendorAnno = PlayerAnnotation(coordinate: locCustomer,
            title: title + " -- " + subtitle, //"current device location",
            subtitle: tweet, //"no vendor registered",
            anType: an)
        
        var annoList = [PlayerAnnotation]()
        annoList.append(vendorAnno)
        
        do {
            if tags?.isEmpty == false {
                let tweetsDict: NSDictionary = try self.doGetBuyers(String(lat), longitude: String(lng), tags: tags!)
                let data: [NSDictionary] = tweetsDict["data"]! as! [NSDictionary]
                for one in data {
                    let latitude: Double = one["coordinates"]!["latitude"]! as! Double
                    let longitude: Double = one["coordinates"]!["longitude"]! as! Double
                    let locVendor = CLLocationCoordinate2D(latitude: latitude,
                        longitude: longitude)
                    
                    let tagsList: [String] = one["tags"]! as! [String]
                    let tagsStr: String = tagsList.joinWithSeparator(",")
                    
                    let buyerAnno = PlayerAnnotation(coordinate: locVendor,
                        title: tagsStr,
                        subtitle: "Looking for: " + tagsStr,
                        anType: .Customer)
                    annoList.append(buyerAnno)
                }
            }
        } catch {
        }
        
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annoList)
        /* And now center the map around the point */
        setCenterOfMapToLocation(locCustomer)
    }
    
    func doRegisterVendor(request: [NSString: AnyObject]) -> NSDictionary? {
        let command = "registerVendor"
        
        var jsonResult: NSDictionary?
        do {
            jsonResult = try utils.rest(command, request: request)
        } catch {
            return nil
        }
        return jsonResult
    }
    
    func doGetBuyers(latitude: String, longitude: String, tags: [String]) throws -> NSDictionary {
        let command = "getBuyers"
        let request : [NSString: AnyObject] =
        [
            "latitude": latitude,
            "longitude": longitude,
            "radius": "500",
            "tags": tags
        ]
        
        return try utils.rest(command, request: request)
    }
    
    func doGetTweet(vendorId: String) -> String{
        var tweet = "No tweet submitted yet"
        
        let command = "getVendorTweet"
        let request = ["vendorId": vendorId]
        
        do {
            let jsonResult = try utils.rest(command, request: request)
            let tweetSaved = jsonResult["status"] as! String
            if  tweetSaved != "FAIL" {
                tweet = jsonResult["data"]!["tweet"] as! String
            }
        } catch {
            return tweet
        }
        
        return tweet
    }
    
    func doRemoveTweet(vendorId: String) -> Bool{
        var success = false
        let command = "removeVendorTweet"
        let request = ["vendorId": vendorId]
        
        do {
            let jsonResult = try utils.rest(command, request: request)
            let tweetSaved = jsonResult["status"] as! String
            if  tweetSaved != "FAIL" {
                success = true
            }
        } catch {
            success = false
        }
        
        return success
    }
    
    func doSendTweet(message: String) -> Bool{
        var success = false
        
        let command = "addTweet"
        let request = ["vendorId": vendorId,
            "tweet": message]
        
        do {
            let jsonResult = try utils.rest(command, request: request)
            let tweetSaved = jsonResult["status"] as! String
            if  tweetSaved != "FAIL" {
                success = true
            }
        } catch {
            return success
        }
        
        return success
    }
    
    func existVendor(id: String) -> Bool {
        var exist = false
        
        let command = "getVendor"
        let request = ["vendorId": id]
        
        var jsonResult: NSDictionary?
        do {
            jsonResult = try utils.rest(command, request: request)
            let vendorExist = jsonResult!["status"] as! String
            if  vendorExist != "FAIL" {
                exist = true
            }
        } catch {
            return exist
        }
        
        return exist
    }
    
    func mapView(mapView: MKMapView,
        viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
            
            if annotation is PlayerAnnotation == false {
                return nil
            }
            
            /* First, typecast the annotation for which the Map View
            fired this delegate message */
            let senderAnnotation = annotation as! PlayerAnnotation
            
            /* We will attempt to get a reusable
            identifier for the pin we are about to create */
            let pinReusableIdentifier = senderAnnotation.anType!.rawValue
            
            /*
            /* Using the identifier we retrieved above, we will
            attempt to reuse a pin in the sender Map View */
            let pinAnnotationView =
            mapView.dequeueReusableAnnotationViewWithIdentifier(
            pinReusableIdentifier)
            
            if pinAnnotationView != nil {
            return pinAnnotationView
            }
            */
            
            
            /* If we fail to reuse a pin, we will create one */
            let annotationView = MKAnnotationView(annotation: senderAnnotation,
                reuseIdentifier: pinReusableIdentifier)
            
            /* Make sure we can see the callouts on top of
            each pin in case we have assigned title and/or
            subtitle to each pin */
            annotationView.canShowCallout = false
            
            if pinReusableIdentifier == AnType.Customer.rawValue {
                if let pinImage = UIImage(named: "CustomerPin") {
                    annotationView.image = pinImage
                }
            } else if pinReusableIdentifier == AnType.NoVendor.rawValue {
                if let pinImage = UIImage(named: "NoVendorPin") {
                    annotationView.image = pinImage
                }
            } else { // if it is not a customer it's a vendor
                if let pinImage = UIImage(named: "VendorPin") {
                    annotationView.image = pinImage
                }
            }
            
            return annotationView
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        for view in views {
            if view.annotation != nil {
                view.canShowCallout = false
                mapView.selectAnnotation(view.annotation!, animated: true)
                view.canShowCallout = true
            }
        }
    }
    
    func getTag() -> Int {
        return ++tag
    }
    
    func tail(text: String, num: Int) ->String {
        var res: String = ""
        let arr = text.characters.split{$0 == " "}.map(String.init)
        
        for var index = 0; index < arr.count && index < num && arr[index] != "--"; ++index {
            res += arr[index]
            res += " "
        }
        return res
    }
    
    func createHint(view: MKAnnotationView, pla: PlayerAnnotation) {
        let venueView = UITextView(frame: CGRectMake(0, -25, 130, 25))
        venueView.text = tail(pla.title!, num: 3)
        venueView.textAlignment = .Right
        if pla.anType == .Vendor || pla.anType == .NoVendor {
            venueView.backgroundColor = UIColor(CIColor: CIColor(string: "0.4392 0.8588 0.5765 1.0"))
        } else {
            venueView.backgroundColor = UIColor(CIColor: CIColor(string: "0.3843 0.7215 1.0 1.0"))
        }
        venueView.tag = getTag()
        pla.tag = venueView.tag
        view.addSubview(venueView)
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if view.annotation == nil {
            return
        }
        let pla: PlayerAnnotation = view.annotation as! PlayerAnnotation
        
        if view.canShowCallout == false {
            print("didSelectAnnotationView - false")
            createHint(view, pla: pla)
        } else {
            print("didSelectAnnotationView - true")
            let tag = pla.tag
            if let viewWithTag = view.viewWithTag(tag) {
                viewWithTag.removeFromSuperview()
            }
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        if view.annotation == nil {
            return
        }
        let pla: PlayerAnnotation = view.annotation as! PlayerAnnotation
        let tag = pla.tag
        if view.canShowCallout == false {
            print("didDeselectAnnotationView - false")
            if let viewWithTag = view.viewWithTag(tag) {
                viewWithTag.removeFromSuperview()
            }
            
        }
        else {
            print("didDeselectAnnotationView - true")
            if let viewWithTag = view.viewWithTag(tag) {
                return
            }
            createHint(view, pla: pla)
        }
    }
    
    // SecondViewController must be a CLLocationManager delegate in order to get the GPS
    func locationManager(manager: CLLocationManager,
        didChangeAuthorizationStatus status: CLAuthorizationStatus){
            print("The authorization status of location services is changed to: ")
            
            switch CLLocationManager.authorizationStatus(){
            case .Authorized:
                print("Authorized")
            case .AuthorizedWhenInUse:
                print("Authorized when in use")
            case .Denied:
                print("Denied")
            case .NotDetermined:
                print("Not determined")
            case .Restricted:
                print("Restricted")
            }
    }
    
    // SecondViewController must be a CLLocationManager delegate
    func locationManager(manager: CLLocationManager,
        didFailWithError error: NSError){
            print("Location manager failed with error = \(error)")
    }
    
    // SecondViewController must be a CLLocationManager delegate. This functions gets the device's GPS location
    func locationManager(manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]) {
            if isRefresh() == false {
                return
            }
            
            let last = locations.count - 1
            
            if vendorId.isEmpty { // use device location
                addPinToMapView(locations[last].coordinate.latitude, lng: locations[last].coordinate.longitude,
                    an: .NoVendor, title: "no vendor registered", subtitle: "current device location",
                    tweet: "", tags: [String]())
            } else {
                let  tweet = doGetTweet(vendorId)
                addPinToMapView(allVendors[vendorId]!.latitude, lng: allVendors[vendorId]!.longitude,
                    an: .Vendor, title: allVendors[vendorId]!.name,
                    subtitle: allVendors[vendorId]!.address, tweet: tweet, tags: allVendors[vendorId]!.tags)
            }
    }
    
    // is it time for refresh
    func isRefresh() -> Bool {
        var isRefresh = true
        
        if startTime == nil {
            startTime = CFAbsoluteTimeGetCurrent()
        } else {
            let now = CFAbsoluteTimeGetCurrent()
            let delta = Int(now - startTime)
            if delta < 35 {
                //print("Too early for refresh \(delta)")
                isRefresh = false
            } else {
                startTime = now
                print("REFRESH")
            }
        }
        
        return isRefresh
    }

    // Factory for the CLLocationManager instance
    func createLocationManager(startImmediately: Bool){
        locationManager = CLLocationManager()
        if let manager = locationManager {
            print("Successfully created the location manager")
            manager.delegate = self
            if startImmediately{
                manager.startUpdatingLocation()
            }
        }
    }
    
    // The view framework method that creates the CLLocationManager
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        /* Are location services available on this device? */
        if CLLocationManager.locationServicesEnabled() {
            
            /* Do we have authorization to access location services? */
            switch CLLocationManager.authorizationStatus(){
            case .Authorized:
                /* Yes, always. */
                createLocationManager(true)
            case .AuthorizedWhenInUse:
                /* Yes, only when our app is in use. */
                createLocationManager(true)
            case .Denied:
                /* No. */
                utils.displayAlertWithTitle(self, title: "Not Determined",
                    message: "Location services are not allowed for this app")
            case .NotDetermined:
                /* We don't know yet; we have to ask */
                createLocationManager(false)
                if let manager = self.locationManager{
                    manager.requestWhenInUseAuthorization()
                }
            case .Restricted:
                /* Restrictions have been applied; we have no access
                to location services. */
                utils.displayAlertWithTitle(self, title: "Restricted",
                    message: "Location services are not allowed for this app")
            }
            
            
        } else {
            /* Location services are not enabled.
            Take appropriate action: for instance, prompt the
            user to enable the location services. */
            print("Location services are not enabled")
        }
    }
    
    func newVendorControllerDidCancel(controller: NewVendorController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func newVendorControllerDidOk(controller: NewVendorController,
        newVendorRequest request: [NSString: AnyObject]) {
            dismissViewControllerAnimated(true, completion: nil)
            let newVendor: NSDictionary? = doRegisterVendor(request)
            if newVendor != nil {
                let vendorId = newVendor!["data"]!["vendorId"]!
                let coordinates = newVendor!["data"]!["coordinates"]! as! [String: Double]
                self.vendorId = vendorId as! String
                self.allVendors[self.vendorId] = VendorData(name: request[NSString(string: "vendor")] as! String,
                    address: request[NSString(string: "address")] as! String,
                    latitude: coordinates["latitude"]!, longitude: coordinates["longitude"]!,
                    tags: request[NSString(string: "tags")] as! [String])
                persist.saveAllVendors(self.allVendors, vendorId: self.vendorId)
                
                addPinToMapView(allVendors[self.vendorId]!.latitude, lng: allVendors[self.vendorId]!.longitude,
                    an: .Vendor, title: allVendors[self.vendorId]!.name, subtitle: allVendors[self.vendorId]!.address,
                    tweet: "no tweet submitted yet", tags: allVendors[self.vendorId]!.tags)
                activateButtons(true)
            }
    }
    
    func selectAnotherVendor(name: String) {
        for (id, vendor) in allVendors {
            if vendor.name != name {
                continue
            }
            if id != vendorId {
                vendorId = id
                persist.saveAllVendors(self.allVendors, vendorId: self.vendorId)
                let  tweet = doGetTweet(vendorId)
                addPinToMapView(allVendors[self.vendorId]!.latitude, lng: allVendors[self.vendorId]!.longitude,
                    an: .Vendor, title: allVendors[self.vendorId]!.name, subtitle: allVendors[self.vendorId]!.address,
                    tweet: tweet, tags: allVendors[self.vendorId]!.tags)
            }
        }
    }
    
    func myVendorControllerDidCancel(controller: MyVendorsController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func myVendorControllerDidOk(controller: MyVendorsController, didFinishSelectingVendor vendor: String) {
        dismissViewControllerAnimated(true, completion: nil)
        selectAnotherVendor(vendor)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "newVendor" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! NewVendorController
            controller.delegate = self
            //controller.resetTags(searchTags)
        } else if segue.identifier == "MyVendors" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! MyVendorsController
            controller.delegate = self
            initMyVendorsController(controller)
        } else if segue.identifier == "tweet" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! TweetController
            controller.delegate = self
        }
    }
    
    func initMyVendorsController(controller: MyVendorsController) {
        var items = [VendorItem]()
        
        for (id, data) in allVendors {
            var checked = false
            if id == vendorId {
                checked = true
            }
            let item = VendorItem(text: data.name, checked: checked)
            items.append(item)
        }
        
        controller.setItems(items)
    }
    
    /* test for each vendor stored on the phone that it stil exists in the server database
    */
    func validateVendors() {
        var changeVendorId = false
        for (id, data) in allVendors {
            let exist =  existVendor(id)
            if exist == true {
                continue
            }
            allVendors.removeValueForKey(id)
            if vendorId == id {
                changeVendorId = true
            }
        }
        if changeVendorId == true  && allVendors.keys.isEmpty == false {
            vendorId = ([String](allVendors.keys))[0]
        }
        
        if allVendors.keys.isEmpty == true {
            vendorId = ""
            persist.saveAllVendors([:], vendorId: "")
        }
    }
    
    func tweetControllerDidCancel(controller: TweetController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tweetControllerDidOk(controller: TweetController, newTweet tweet: String) {
        dismissViewControllerAnimated(true, completion: nil)
        doSendTweet(tweet)
        
        addPinToMapView(allVendors[self.vendorId]!.latitude, lng: allVendors[self.vendorId]!.longitude,
            an: .Vendor, title: allVendors[self.vendorId]!.name, subtitle: allVendors[self.vendorId]!.address,
            tweet: tweet, tags: allVendors[self.vendorId]!.tags)
    }
    
    func activateButtons(isActive: Bool) {
        buttonTweet.enabled = isActive
        buttonSilent.enabled = isActive
        buttonVendors.enabled = isActive
    }
    
    @IBAction func onTweet(sender: AnyObject) {
        if vendorId.isEmpty {
            utils.displayAlertWithTitle(self, title: "No vendor created yet",
                message: "You need to create a vendor before you can send")
            return
        }
    }
    
    @IBAction func onSilent(sender: AnyObject) {
        let success = doRemoveTweet(vendorId)
        if success == true {
            utils.displayAlertWithTitle(self, title: "Command succeeded",
                message: "Tweet was removed")
            addPinToMapView(allVendors[self.vendorId]!.latitude, lng: allVendors[self.vendorId]!.longitude,
                an: .Vendor, title: allVendors[self.vendorId]!.name, subtitle: allVendors[self.vendorId]!.address,
                tweet: "no tweet submitted yet", tags: allVendors[self.vendorId]!.tags)
        } else {
            utils.displayAlertWithTitle(self, title: "Command failed",
                message: "Tweet was not removed")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.mapType = .Standard
        mapView.frame = view.frame
        mapView.delegate = self
        view.addSubview(mapView)
        
        if vendorId.isEmpty == true {
            activateButtons(false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
