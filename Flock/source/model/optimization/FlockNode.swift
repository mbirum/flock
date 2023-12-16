
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
    var annotationType: String {
        if isDriver {
            return "source"
        }
        else if isDestination {
            return "destination"
        }
        else {
            return "pickup"
        }
    }
    var isDriver: Bool = false
    var isDestination: Bool = false
    @objc dynamic var pin: MKMapItem?
    
    init(riderId: UUID?, riderName: String, locationString: String) {
        self.riderId = riderId
        self.riderName = riderName
        self.locationString = locationString
        super.init()
        requestPin()
    }
    
    init(riderId: UUID?, riderName: String, locationString: String, isDriver: Bool) {
        self.riderId = riderId
        self.riderName = riderName
        self.locationString = locationString
        self.isDriver = isDriver
        super.init()
        requestPin()
    }
    
    init(riderId: UUID?, riderName: String, locationString: String, isDestination: Bool) {
        self.riderId = riderId
        self.riderName = riderName
        self.locationString = locationString
        self.isDestination = isDestination
        super.init()
        requestPin()
    }
    
    func requestPin() -> Void {
        // if location hasnt changed in cache, return cached item
        if !RiderLocationCache.hasLocationChanged(id: self.riderId, locationString: self.locationString) {
            guard let uRiderId = riderId else { return }
            guard let uCacheItem = RiderLocationCache.get(uRiderId) else { return }
            self.pin = nil
            self.pin = uCacheItem.pin
        }
        else {
            LocationSearchService.translateLocationToMapItem(
                location: self.locationString,
                mapItemHandler: { item in
                    self.pin = item
                    guard let uRiderId = self.riderId else { return }
                    RiderLocationCache.put(id: uRiderId, locationString: self.locationString, pin: item)
                }
            )
        }
    }
}
