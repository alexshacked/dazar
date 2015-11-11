import UIKit
import CoreLocation
import MapKit

class MyAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String){
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        super.init()
    }
    
}

class FirstViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    // holds the CLLocationManager instance created in viewDidAppear()
    var locationManager: CLLocationManager?
    
    var mapView: MKMapView!
    
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
    
    func addPinToMapView(lat: Double, lng: Double){
        
        /* This is just a sample location */
        let location = CLLocationCoordinate2D(latitude: lat,
            longitude: lng)
        
        /* Create the annotation using the location */
        let annotation = MyAnnotation(coordinate: location,
            title: "My Title",
            subtitle: "My Sub Title")
        
        /* And eventually add it to the map */
        let annotations = mapView.annotations
        if annotations.count == 1 {
            let an = annotations[0]
            if an.coordinate.latitude == lat && an.coordinate.longitude == lng {
                return
            }
        }
        
        mapView.removeAnnotations(annotations)
        mapView.addAnnotation(annotation)
        /* And now center the map around the point */
        setCenterOfMapToLocation(location)
        
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
            let last = locations.count - 1
            print("Latitude = \(locations[last].coordinate.latitude)")
            print("Longitude = \(locations[last].coordinate.longitude)")
            
            addPinToMapView(locations[last].coordinate.latitude, lng: locations[last].coordinate.longitude)
    }
    
    func displayAlertWithTitle(title: String, message: String){
        let controller = UIAlertController(title: title,
            message: message,
            preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(title: "OK",
            style: .Default,
            handler: nil))
        
        presentViewController(controller, animated: true, completion: nil)
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
                displayAlertWithTitle("Not Determined",
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
                displayAlertWithTitle("Restricted",
                    message: "Location services are not allowed for this app")
            }
            
            
        } else {
            /* Location services are not enabled.
            Take appropriate action: for instance, prompt the
            user to enable the location services. */
            print("Location services are not enabled")
        }
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

