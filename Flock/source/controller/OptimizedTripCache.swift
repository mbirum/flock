//
//  OptimizedTripCache.swift
//  Flock
//
//  Created by Matt Birum on 12/14/23.
//

import Foundation

class OptimizedTripCache: ObservableObject {
    
    public static var shared: OptimizedTripCache = OptimizedTripCache()
    
    @Published var lookup:[UUID: OptimizedTripCacheItem] = [:]
    
    static func get(_ id: UUID) -> OptimizedTripCacheItem? {
        return shared.lookup[id]
    }
    
    static func put(trip: Trip, routeStack: [FlockRoute]) -> Void {
        let tripComparison: TripComparison = getComparisonObjectForTrip(trip)
        shared.lookup[trip.id] = OptimizedTripCacheItem(tripComparison: tripComparison, routeStack: routeStack)
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
        for rider in trip.riders {
            if rider.isDriver {
                driverIds.append(rider.id)
            }
        }
        return TripComparison(
            destination: trip.destination,
            useSuggestedDrivers: trip.useSuggestedDrivers,
            riderLocations: riderLocations,
            driverIds: driverIds
        )
    }
    
}


struct OptimizedTripCacheItem {
    var tripComparison: TripComparison
    var routeStack: [FlockRoute]
}

struct TripComparison: Equatable {
    var destination: String
    var useSuggestedDrivers: Bool
    var riderLocations: [String]
    var driverIds: [UUID]
    
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
        return true
    }
}
