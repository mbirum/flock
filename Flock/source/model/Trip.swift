
import Foundation

struct Trip: Encodable, Decodable, Hashable, Identifiable {
    var id = UUID()
    var destinationCacheID: UUID = UUID()
    var name: String
    var destination: String
    var useSuggestedDrivers: Bool
    var riders: [Rider] = []
    var drivers: Int { riders.filter({$0.isDriver}).count }
    var passengers: Int { riders.filter({!$0.isDriver}).count }
    
    init(name: String, destination: String, useSuggestedDrivers: Bool, riders: [Rider] = []) {
        self.name = name
        self.destination = destination
        self.useSuggestedDrivers = useSuggestedDrivers
        self.riders = riders
    }
    
    mutating func from(_ trip: Trip) -> Void {
        self.name = trip.name
        self.destination = trip.destination
        self.riders = trip.riders
    }
}
