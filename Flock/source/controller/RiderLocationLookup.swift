
import Foundation
import MapKit

class RiderLocationLookup: ObservableObject {
    
    public static var shared: RiderLocationLookup = RiderLocationLookup()
    
    @Published var lookup:[UUID: MKMapItem] = [:]
    
    func get(_ id: UUID) -> MKMapItem? {
        return lookup[id]
    }
    
    func put(id: UUID, location: MKMapItem) -> Void {
        lookup[id] = location
    }
    
    static func putFromLocationString(id: UUID, location: String) -> Void {
        LocationSearchService.translateLocationToMapItem(
            location: location,
            mapItemHandler: { item in
                RiderLocationLookup.shared.lookup[id] = item
            }
        )
    }
}
