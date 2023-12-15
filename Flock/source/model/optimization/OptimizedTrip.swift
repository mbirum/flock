
import Foundation
import MapKit
import mbutils

class OptimizedTrip {
    var trip: Trip {
        didSet {
            self.requestRoutes()
        }
    }
    
    var allNodes: [FlockNode] = []
    var routeProspects: [FlockRoute] = []
    var routeStack: [FlockRoute] = []
    var suggestedDriverId: UUID? = nil
    
    init(_ trip: Trip) {
        self.trip = trip
        requestRoutes()
    }
    
    func requestRoutes() -> Void {
        if !OptimizedTripCache.hasTripChanged(trip) {
            guard let uCacheItem = OptimizedTripCache.get(trip.id) else { return }
            self.routeStack = uCacheItem.routeStack
            return
        }
        
        var flockNodes: [FlockNode] = []
        for rider in trip.riders {
            flockNodes.append(FlockNode(
                riderId: rider.id,
                riderName: rider.name,
                locationString: rider.location,
                isDriver: rider.isDriver && !trip.useSuggestedDrivers,
                annotationType: "pickup"
            ))
        }
        flockNodes.append(FlockNode(
            riderId: trip.destinationCacheID,
            riderName: "Destination",
            locationString: trip.destination,
            isDestination: true,
            annotationType: "destination"
        ))
        
        var routeProspects: [FlockRoute] = []
        
        for i in 0..<flockNodes.count {
            if !flockNodes[i].isDestination {
                for ii in 0..<flockNodes.count {
                    if i != ii {
                        let route: FlockRoute = FlockRoute(from: flockNodes[i], to: flockNodes[ii])
                        routeProspects.append(route)
                    }
                }
            }
        }
        
        self.allNodes = flockNodes
        self.routeProspects = routeProspects
        startRouteRequestChecker()
    }
    
    func startRouteRequestChecker() -> Void {
        TimerBasedConditionCheck.create(condition: {
            return self.areRouteRequestsComplete()
        }, complete: {
            self.optimizeRoutes()
        })
    }
    
    func areRouteRequestsComplete() -> Bool {
        for prospect in routeProspects {
            guard let _ = prospect.route else {
                return false
            }
        }
        return true
    }
    
    func optimizeRoutes() -> Void {
        if !OptimizedTripCache.hasTripChanged(trip) {
            guard let uCacheItem = OptimizedTripCache.get(trip.id) else { return }
            self.routeStack = uCacheItem.routeStack
            return
        }
        if trip.useSuggestedDrivers {
            optimizeRoutesForSuggestedDrivers()
        }
        else {
            optimizeRoutesForSpecifiedDrivers()
        }
        OptimizedTripCache.put(trip: trip, routeStack: self.routeStack)
    
    }
    
    func optimizeRoutesForSuggestedDrivers() -> Void {
        var nodeRouteMap: [FlockNode:NodeSpecificRouteCollections] = [:]
        for node in allNodes {
            let routesFrom: [FlockRoute] = routeProspects.filter({$0.from.riderId == node.riderId})
            let routesTo: [FlockRoute] = routeProspects.filter({$0.to.riderId == node.riderId})
            nodeRouteMap[node] = NodeSpecificRouteCollections(from: routesFrom, to: routesTo)
        }
        var newRouteStack: [FlockRoute] = []
        var newRouteStackTotalDistance: Double = Double.greatestFiniteMagnitude
        for node in allNodes {
            let tripProspects = createTripProspectsForAssumedDriver(driver: node, nodeRouteMap: nodeRouteMap)
            for tripProspect in tripProspects {
                if tripProspect.count > 0 {
                    var totalDistance: Double = 0
                    for flockRoute in tripProspect {
                        totalDistance += flockRoute.route!.distance
                    }
                    if totalDistance < newRouteStackTotalDistance {
                        newRouteStack = tripProspect
                        newRouteStackTotalDistance = totalDistance
                    }
                }
            }
        }
        self.routeStack = newRouteStack
        
        // set driver based on optimized route suggestion
        if self.routeStack.count > 0 {
            let firstNode = self.routeStack[0].from
            self.suggestedDriverId = firstNode.riderId
        }
//        printTripString()
    }
    
    func optimizeRoutesForSpecifiedDrivers() -> Void {
        var nodeRouteMap: [FlockNode:NodeSpecificRouteCollections] = [:]
        for node in allNodes {
            let routesFrom: [FlockRoute] = routeProspects.filter({$0.from.riderId == node.riderId})
            let routesTo: [FlockRoute] = routeProspects.filter({$0.to.riderId == node.riderId})
            nodeRouteMap[node] = NodeSpecificRouteCollections(from: routesFrom, to: routesTo)
        }
        var newRouteStack: [FlockRoute] = []
        var newRouteStackTotalDistance: Double = Double.greatestFiniteMagnitude
        for node in allNodes {
            if node.isDriver {
                let tripProspects = createTripProspectsForAssumedDriver(driver: node, nodeRouteMap: nodeRouteMap)
                for tripProspect in tripProspects {
                    if tripProspect.count > 0 {
                        var totalDistance: Double = 0
                        for flockRoute in tripProspect {
                            totalDistance += flockRoute.route!.distance
                        }
                        if totalDistance < newRouteStackTotalDistance {
                            newRouteStack = tripProspect
                            newRouteStackTotalDistance = totalDistance
                        }
                    }
                }
            }
        }
        self.routeStack = newRouteStack
//        printTripString()
    }
    
    func printTripString() -> Void {
        var tripString: String = ""
        for i in 0..<self.routeStack.count {
            let route = self.routeStack[i]
            if i == 0 {
                tripString += route.from.riderName + " -> "
            }
            tripString += route.to.riderName + " -> "
        }
        print(tripString)
    }
    
    func createTripProspectsForAssumedDriver(driver: FlockNode, nodeRouteMap: [FlockNode:NodeSpecificRouteCollections]) -> [[FlockRoute]] {
        var tripProspects: [[FlockRoute]] = [[]]
        
        // get routes from assumed driver
        let routesFrom: [FlockRoute] = nodeRouteMap[driver]!.from
        for routeFrom in routesFrom {
            var nodesAccountedFor: Set<UUID> = Set()
            // first add assumed driver to list of riders accounted for
            nodesAccountedFor.insert(driver.riderId!)
            var tripProspect: [FlockRoute] = []
            tripProspect.append(routeFrom)
            addToProspectForNode(
                node: routeFrom.to,
                fromNode: driver,
                tripProspect: &tripProspect,
                nodeRouteMap: nodeRouteMap,
                nodesAccountedFor: &nodesAccountedFor
            )
            if nodesAccountedFor.count == allNodes.count {
                tripProspects.append(tripProspect)
            }
        }
        
        return tripProspects
    }
    
    func addToProspectForNode(node: FlockNode, fromNode: FlockNode, tripProspect: inout [FlockRoute], nodeRouteMap: [FlockNode:NodeSpecificRouteCollections], nodesAccountedFor: inout Set<UUID>) -> Void {
        if node.isDestination {
            nodesAccountedFor.insert(node.riderId!)
            return
        }
        let routesFrom: [FlockRoute] = nodeRouteMap[node]!.from
        for routeFrom in routesFrom {
            // if we're not going back to where we came from
            if !nodesAccountedFor.contains(routeFrom.to.riderId!) {
                nodesAccountedFor.insert(node.riderId!)
                tripProspect.append(routeFrom)
                addToProspectForNode(
                    node: routeFrom.to,
                    fromNode: node,
                    tripProspect: &tripProspect,
                    nodeRouteMap: nodeRouteMap,
                    nodesAccountedFor: &nodesAccountedFor
                )
            }
        }
        
    }
}

struct NodeSpecificRouteCollections {
    var from: [FlockRoute]
    var to: [FlockRoute]
}
