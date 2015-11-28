import UIKit
import MapKit

/* This allows us to check for equality between two items
of type PinColor */
func == (left: AnType, right: AnType) -> Bool{
    return left.rawValue == right.rawValue
}

/* The various pin colors that our annotation can have */
enum AnType : String {
    case Customer = "Customer"
    case Vendor = "Vendor"
    case NoVendor = "NoVendor"
}


class PlayerAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2DMake(0, 0)
    var title: String?
    var subtitle: String?
    var anType: AnType?
    var tag = 0
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, anType: AnType) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.anType = anType
        super.init()
    }
    
    convenience init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
            self.init(coordinate: coordinate,
                title: title,
                subtitle: subtitle,
                anType: .Vendor)
    }    
}





