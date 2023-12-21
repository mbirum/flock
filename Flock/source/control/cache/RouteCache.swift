
import Foundation
import MapKit

class RouteCache: ObservableObject {
    
    public static var shared: RouteCache = RouteCache()
    
    @Published var lookup:[RouteCacheKey: RouteCacheItem] = [:]
    
    static func get(_ key: RouteCacheKey) -> RouteCacheItem? {
        return shared.lookup[key]
    }
    
    static func put(key: RouteCacheKey, route: MKRoute) -> Void {
        shared.lookup[key] = RouteCacheItem(route: route)
    }

    static func isRouteCached(source: String, destination: String) -> Bool {
        let key: RouteCacheKey = RouteCacheKey(source: source, destination: destination)
        guard let _ = shared.lookup[key] else { return false }
        return true
    }
    
    static func initialize(from: Trip) -> Void {
        let nodeCount = from.riders.count
        let initializationLimit = (nodeCount * nodeCount) / 2
        var flockNodes: [FlockNode] = []
        for rider in from.riders {
            flockNodes.append(FlockNode(
                riderId: rider.id,
                riderName: rider.name,
                locationString: rider.location,
                capacity: rider.passengerCapacity,
                isDriver: rider.isDriver && !from.useSuggestedDrivers
            ))
        }
        flockNodes.append(FlockNode(
            riderId: from.destinationCacheID,
            riderName: "Destination",
            locationString: from.destination,
            capacity: 1,
            isDestination: true
        ))
        
        var routeProspects: [FlockRoute] = []
        
        var initCount: Int = 0
        forEachNode: for i in 0..<flockNodes.count {
            if !flockNodes[i].isDestination {
                forEveryOtherNode: for ii in 0..<flockNodes.count {
                    if i != ii {
                        let route: FlockRoute = FlockRoute(from: flockNodes[i], to: flockNodes[ii])
                        routeProspects.append(route)
                        initCount += 1
                        if (initCount >= initializationLimit) {
                            break forEachNode
                        }
                    }
                }
            }
        }
    }
    
}

struct RouteCacheKey: Hashable {
    var source: String
    var destination: String
    
    static func == (lhs: RouteCacheKey, rhs: RouteCacheKey) -> Bool {
        return lhs.source == rhs.source && lhs.destination == rhs.destination
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(destination)
    }
}

struct RouteCacheItem {
    var route: MKRoute
}
