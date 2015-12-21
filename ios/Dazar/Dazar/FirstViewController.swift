import UIKit
import CoreLocation
import MapKit

struct Coordinates {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
}

class FirstViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate,
                            TagsControllerDelegate, LocationControllerDelegate {
    // holds the CLLocationManager instance created in viewDidAppear()
    var locationManager: CLLocationManager?
    var mapView: MKMapView!
    var startTime: CFAbsoluteTime! = nil
    var tag = 1
    var searchTags: [String] = ["all"]
    var searchCoordinates: Coordinates? = nil
    var searchAddress: String = ""
    var utils = Utils()
    var neverAppeared = true
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        mapView = MKMapView()
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
    
    func addPinToMapView(lat: Double, lng: Double, pseudoBuyer: Bool) {
        /* The locations */
        let locCustomer = CLLocationCoordinate2D(latitude: lat,
            longitude: lng)
        
        /* Create the annotation using the location */
        let custAnno = PlayerAnnotation(coordinate: locCustomer,
            title: "Me",
            subtitle: "Im here",
            anType: .Customer)
        
        var annoList = [PlayerAnnotation]()
        annoList.append(custAnno)
        do {
            let tweetsDict: NSDictionary = try doGetTweets(String(lat), longitude: String(lng),
                pseudoBuyer: pseudoBuyer)
            let data: [NSDictionary] = tweetsDict["data"]! as! [NSDictionary]
            for one in data {
                let latitude: Double = one["coordinates"]!["latitude"]! as! Double
                let longitude: Double = one["coordinates"]!["longitude"]! as! Double
                let locVendor = CLLocationCoordinate2D(latitude: latitude,
                    longitude: longitude)
                
                let name: String = one["name"]! as! String
                let tweet: String = one["tweet"]! as! String
                let tagsList: [String] = one["tags"]! as! [String]
                let tags = tagsList.joinWithSeparator(",")
                
                let vendAnno = PlayerAnnotation(coordinate: locVendor,
                    title: name + " -- " + tags,
                    subtitle: tweet,
                    anType: .Vendor)
                annoList.append(vendAnno)

            }
        } catch {
        }
        
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annoList)
        /* And now center the map around the point */
        setCenterOfMapToLocation(locCustomer)
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
        if arr.count <= num {
            return text
        }
        
        for var index = arr.count - num; index < arr.count; ++index {
            res += arr[index]
            res += " "
        }
        return res
    }

    func createHint(view: MKAnnotationView, pla: PlayerAnnotation) {
        let venueView = UITextView(frame: CGRectMake(0, -25, 130, 25))
        venueView.text = tail(pla.subtitle!, num: 3)
        venueView.textAlignment = .Right
        if pla.anType == .Vendor {
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
    
    // FirstViewController must be a CLLocationManager delegate in order to get the GPS
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
    
    // FirstViewController must be a CLLocationManager delegate
    func locationManager(manager: CLLocationManager,
        didFailWithError error: NSError){
            print("Location manager failed with error = \(error)")
    }
    
    // FirstViewController must be a CLLocationManager delegate. This functions gets the device's GPS location
    func locationManager(manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]) {
            if isRefresh() == false {
                return
            }
            
            let last = locations.count - 1
            
            if searchCoordinates == nil { // use device location
                addPinToMapView(locations[last].coordinate.latitude, lng: locations[last].coordinate.longitude,
                    pseudoBuyer: false)
            } else {
                addPinToMapView(searchCoordinates!.latitude, lng: searchCoordinates!.longitude, pseudoBuyer: true)
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
    
    func address2Coordinates(address: String) -> Coordinates {
        var coord: Coordinates = Coordinates()
        
        let command = "getCoordinates"
        let request : [NSString: AnyObject] =
        [
            "address": address
        ]
        
        
        do {
            let jsonResult: NSDictionary = try utils.rest(command, request: request)
            let data: NSDictionary = jsonResult["data"]! as! NSDictionary
            coord.latitude = data["lat"] as! Double
            coord.longitude = data["lng"] as! Double
            return coord
        } catch {
            
        }
        
        return coord
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
        
        if neverAppeared == true {
            neverAppeared = false
        
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
        } else { // neverAppeared == false
            startUpdateLocation()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        stopUpdateLocation()
    }
    
    func doGetTweets(latitude: String, longitude: String, pseudoBuyer: Bool) throws -> NSDictionary {
        let id = UIDevice.currentDevice().identifierForVendor?.UUIDString
        let command = "getTweets"
        
        var pseudo = 0
        if pseudoBuyer == true {
            pseudo = 1
        }
        let request : [NSString: AnyObject] =
        [
            "latitude": latitude,
            "longitude": longitude,
            "radius": "500",
            "tags": searchTags,
            "buyerId": String(id),
            "pseudoBuyer": String(pseudo)
        ]
        
        let jsonResult: NSDictionary = try utils.rest(command, request: request)
        
        return jsonResult
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "searchTags" { // 2
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! TagsController
            controller.delegate = self
            controller.resetTags(searchTags)
        } else if segue.identifier == "searchLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationController
            controller.setSearchLocation(searchAddress)

            controller.delegate = self
        }
    }
    
    func tagsControllerDidCancel(controller: TagsController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tagsController(controller: TagsController, didFinishSelectingTags tags: [String]) {
        searchTags = tags
        dismissViewControllerAnimated(true, completion: nil)
        
        trigerUpdateLocation()
    }
    
    func locationControllerDidCancel(controller: LocationController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func locationController(controller: LocationController, didFinishSelectingLocation location: String) {
        print("didFinishSelectingLocation: " + location)
        if location.isEmpty == false {
            searchCoordinates = address2Coordinates(location)
        } else {
            searchCoordinates = nil
        }
        searchAddress = location
        
        dismissViewControllerAnimated(true, completion: nil)
        
        trigerUpdateLocation()
    }
    
    func trigerUpdateLocation() {
        startTime = nil
        locationManager?.stopUpdatingLocation()
        locationManager?.startUpdatingLocation()
    }
    
    func stopUpdateLocation() {
        locationManager?.stopUpdatingLocation()
    }
    
    func startUpdateLocation() {
        locationManager?.startUpdatingLocation()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.mapType = .Standard
        mapView.frame = view.frame
        mapView.delegate = self
        view.addSubview(mapView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

