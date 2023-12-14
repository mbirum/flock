
import Foundation
import MapKit

class RiderLocationCache: ObservableObject {
    
    public static var shared: RiderLocationCache = RiderLocationCache()
    
    @Published var lookup:[UUID: LocationCacheItem] = [:]
    
    static func get(_ id: UUID) -> LocationCacheItem? {
        return shared.lookup[id]
    }
    
    static func put(id: UUID, locationString: String, pin: MKMapItem) -> Void {
        shared.lookup[id] = LocationCacheItem(locationString: locationString, pin: pin)
    }
    
    static func hasLocationChanged(id: UUID?, locationString: String) -> Bool {
        guard let unwrappedId = id else { return true }
        guard let cachedLocation = shared.lookup[unwrappedId] else { return true }
        return cachedLocation.locationString != locationString
    }
}

struct LocationCacheItem {
    var locationString: String
    var pin: MKMapItem
}
