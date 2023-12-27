
import Foundation

class OptimizedTripCache: ObservableObject {
    
    public static var shared: OptimizedTripCache = OptimizedTripCache()
    
    @Published var lookup:[UUID: OptimizedTripCacheItem] = [:]
    
    static func get(_ id: UUID) -> OptimizedTripCacheItem? {
        return shared.lookup[id]
    }
    
    static func put(trip: Trip, optimizedTrip: OptimizedTrip) -> Void {
        let tripComparison: TripComparison = getComparisonObjectForTrip(trip)
        shared.lookup[trip.id] = OptimizedTripCacheItem(tripComparison: tripComparison, optimizedTrip: optimizedTrip)
    }
    
    
    static func hasTripChanged(_ trip: Trip) -> Bool {
        guard let cachedOptimizedTrip = shared.lookup[trip.id] else { return true }
        let tripComparison: TripComparison = getComparisonObjectForTrip(trip)
        return cachedOptimizedTrip.tripComparison != tripComparison
    }
    
    static func getComparisonObjectForTrip(_ trip: Trip) -> TripComparison {
        var riderLocations: [String] = []
        for rider in trip.riders { riderLocations.append(rider.location) }
        var driverIds: [UUID] = []
        var capacityKeys: [String] = []
        for rider in trip.riders {
            let capacityKey = String(rider.passengerCapacity) + "-" + rider.id.uuidString
            capacityKeys.append(capacityKey)
            if rider.isDriver {
                driverIds.append(rider.id)
            }
        }
        return TripComparison(
            destination: trip.destination,
            useSuggestedDrivers: trip.useSuggestedDrivers,
            riderLocations: riderLocations,
            driverIds: driverIds,
            capacityKeys: capacityKeys
        )
    }
    
}


struct OptimizedTripCacheItem {
    var tripComparison: TripComparison
    var optimizedTrip: OptimizedTrip
}

struct TripComparison: Equatable {
    var destination: String
    var useSuggestedDrivers: Bool
    var riderLocations: [String]
    var driverIds: [UUID]
    var capacityKeys: [String]
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        if lhs.riderLocations.count != rhs.riderLocations.count {
            return false
        }
        for locationString in lhs.riderLocations {
            if !rhs.riderLocations.contains(locationString) {
                return false
            }
        }
        for locationString in rhs.riderLocations {
            if !lhs.riderLocations.contains(locationString) {
                return false
            }
        }
        if lhs.driverIds.count != rhs.driverIds.count {
            return false
        }
        for driverId in lhs.driverIds {
            if !rhs.driverIds.contains(driverId) {
                return false
            }
        }
        for driverId in rhs.driverIds {
            if !lhs.driverIds.contains(driverId) {
                return false
            }
        }
        if lhs.destination != rhs.destination {
            return false
        }
        if lhs.useSuggestedDrivers != rhs.useSuggestedDrivers {
            return false
        }
        for capacityKey in lhs.capacityKeys {
            if !rhs.capacityKeys.contains(capacityKey) {
                return false
            }
        }
        for capacityKey in rhs.capacityKeys {
            if !lhs.capacityKeys.contains(capacityKey) {
                return false
            }
        }
        return true
    }
}
