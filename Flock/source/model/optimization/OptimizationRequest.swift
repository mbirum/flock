
import Foundation

class OptimizationRequest {
    var trip: Trip
    var flockRoutes: [FlockRoute] = []
    var allNodes: [FlockNode] {
        var nodes: Set<FlockNode> = []
        for route in flockRoutes {
            nodes.insert(route.from)
            nodes.insert(route.to)
        }
        return Array(nodes)
    }
    var nodeMap: [FlockNode:[FlockRoute]] {
        var map: [FlockNode:[FlockRoute]] = [:]
        for node in allNodes {
            map[node] = flockRoutes.filter({$0.from.riderId == node.riderId})
        }
        return map
    }
    
    var optimizedTrip: OptimizedTrip?
//    var tripVariations: [TripVariation] = []
    
    init(_ trip: Trip) {
        self.trip = trip
    }
}
