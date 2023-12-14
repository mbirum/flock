
import Foundation
import MapKit

class FlockNode: NSObject {
    var riderId: UUID?
    var riderName: String
    var locationString: String {
        didSet {
            requestPin()
        }
    }
    var annotationType: String
    var isDriver: Bool = false
    var isDestination: Bool = false
    @objc dynamic var pin: MKMapItem?
    
    init(riderId: UUID?, riderName: String, locationString: String, annotationType: String) {
        self.riderId = riderId
        self.riderName = riderName
        self.locationString = locationString
        self.annotationType = annotationType
        super.init()
        requestPin()
    }
    
    init(riderId: UUID?, riderName: String, locationString: String, isDriver: Bool, annotationType: String) {
        self.riderId = riderId
        self.riderName = riderName
        self.locationString = locationString
        self.isDriver = isDriver
        self.annotationType = annotationType
        super.init()
        requestPin()
    }
    
    init(riderId: UUID?, riderName: String, locationString: String, isDestination: Bool, annotationType: String) {
        self.riderId = riderId
        self.riderName = riderName
        self.locationString = locationString
        self.isDestination = isDestination
        self.annotationType = annotationType
        super.init()
        requestPin()
    }
    
    func requestPin() -> Void {
        // if location hasnt changed in cache, return cached item
        if !RiderLocationCache.hasLocationChanged(id: self.riderId, locationString: self.locationString) {
            guard let unwrappedRiderId = riderId else { return }
            guard let unwrappedCacheItem = RiderLocationCache.get(unwrappedRiderId) else { return }
            self.pin = nil
            self.pin = unwrappedCacheItem.pin
        }
        else {
            LocationSearchService.translateLocationToMapItem(
                location: self.locationString,
                mapItemHandler: { item in
                    self.pin = item
                    guard let unwrappedRiderId = self.riderId else { return }
                    RiderLocationCache.put(id: unwrappedRiderId, locationString: self.locationString, pin: item)
                }
            )
        }
    }
}
