
import Foundation
import MapKit

class FlockNode: NSObject {
    var riderId: UUID?
    var locationString: String {
        didSet {
            requestPin()
        }
    }
    var annotationType: String
    @objc dynamic var pin: MKMapItem?
    
    init(riderId: UUID?, locationString: String, annotationType: String) {
        self.riderId = riderId
        self.locationString = locationString
        self.annotationType = annotationType
        super.init()
        requestPin()
    }
    
    func requestPin() -> Void {
        if !RiderLocationCache.hasLocationChanged(id: self.riderId, locationString: self.locationString) {
            guard let unwrappedRiderId = riderId else { return }
            print("using cached location for \(unwrappedRiderId)")
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
                    print("putting cache location for \(unwrappedRiderId)")
                    RiderLocationCache.put(id: unwrappedRiderId, locationString: self.locationString, pin: item)
                }
            )
        }
    }
}
