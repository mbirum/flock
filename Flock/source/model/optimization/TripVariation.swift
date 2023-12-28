
import Foundation

class TripVariation: Hashable {
    var routes: [FlockRoute] = []
    
    init(routes: [FlockRoute]) {
        self.routes = routes
    }
    
    init() {
        routes = []
    }
    
    var totalTime: Double {
        var totalTime: Double = 0
        for route in routes {
            totalTime += route.route?.expectedTravelTime ?? 0
        }
        return totalTime
    }
    
    var driver: FlockNode? {
        return routes.first?.from ?? nil
    }
    
    var allNodes: [FlockNode] {
        var nodes: Set<FlockNode> = []
        for route in routes {
            nodes.insert(route.from)
            nodes.insert(route.to)
        }
        return Array(nodes)
    }
    
    func setDriver() -> Void {
        guard let uDriver = driver else { return }
        uDriver.isDriver = true
    }
    
    func contains(_ node: FlockNode) -> Bool {
        for existingNode in allNodes {
            if existingNode.riderId == node.riderId {
                return true
            }
        }
        return false
    }
    
    func isOverlappingWithOthers(others: [TripVariation]) -> Bool {
        for node in self.allNodes {
            if node.isDestination {
                continue
            }
            for other in others {
                if other.contains(node) {
                    return true
                }
            }
        }
        return false
    }
    
    static func == (lhs: TripVariation, rhs: TripVariation) -> Bool {
        if lhs.routes.count != rhs.routes.count {
            return false
        }
        for route1 in lhs.routes {
            var found = false
            for route2 in rhs.routes {
                if route2.id == route1.id {
                    found = true
                    break
                }
            }
            if !found {
                return false
            }
        }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(routes)
    }
}

