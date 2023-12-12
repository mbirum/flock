
import Foundation
import MapKit

class FlockNode: NSObject {
    var locationString: String {
        didSet {
            requestPin()
        }
    }
    var annotationType: String
    @objc dynamic var pin: MKMapItem?
    
    init(_ locationString: String, annotationType: String) {
        self.locationString = locationString
        self.annotationType = annotationType
        super.init()
        requestPin()
    }
    
    func requestPin() -> Void {
        LocationSearchService.translateLocationToMapItem(
            location: self.locationString,
            mapItemHandler: { item in
                self.pin = item
            }
        )
    }
}
