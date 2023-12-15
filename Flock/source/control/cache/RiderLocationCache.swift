
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
    
    static func putFromLocationString(id: UUID, locationString: String) -> Void {
        LocationSearchService.translateLocationToMapItem(
            location: locationString,
            mapItemHandler: { item in
                RiderLocationCache.put(id: id, locationString: locationString, pin: item)
            }
        )
    }
    
    static func hasLocationChanged(id: UUID?, locationString: String) -> Bool {
        guard let uId = id else { return true }
        guard let cachedLocation = shared.lookup[uId] else { return true }
        return cachedLocation.locationString != locationString
    }
    
    static func initializeCache(from: Trip) -> Void {
        if RiderLocationCache.hasLocationChanged(id: from.destinationCacheID, locationString: from.destination) {
            RiderLocationCache.putFromLocationString(id: from.destinationCacheID, locationString: from.destination)
        }
        for rider in from.riders {
            if RiderLocationCache.hasLocationChanged(id: rider.id, locationString: rider.location) {
                RiderLocationCache.putFromLocationString(id: rider.id, locationString: rider.location)
            }
        }
    }
    
    static func initializeCache(from: [Trip]) -> Void {
        for trip in from {
            RiderLocationCache.initializeCache(from: trip)
        }
    }
    
}

struct LocationCacheItem {
    var locationString: String
    var pin: MKMapItem
}
