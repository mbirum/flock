
import Foundation
import MapKit
import mbutils

class OptimizedTrip: Equatable {
    static var queue: [OptimizationRequest] = []
    var trip: Trip {
        didSet {
            self.requestRoutes()
        }
    }
    
    var allNodes: [FlockNode] = []
    var routeProspects: [FlockRoute] = []
    var routeStack: [FlockRoute] = []
    var suggestedDriverId: UUID? = nil
    var suggestedDriverIds: [UUID] = []
    
    init(_ trip: Trip) {
        self.trip = trip
        requestRoutes()
    }
    
    static func isRequestable() -> Bool {
        return OptimizedTrip.queue.count == 0
    }
    
    func requestRoutes() -> Void {
        
        if !OptimizedTripCache.hasTripChanged(trip) {
            guard let uCacheItem = OptimizedTripCache.get(trip.id) else { return }
            self.routeStack = uCacheItem.routeStack
            OptimizedTrip.queue = []
            return
        }
        if OptimizedTrip.queue.count > 0 {
            return
        }
        OptimizedTrip.queue.append(OptimizationRequest())
        var flockNodes: [FlockNode] = []
        for rider in trip.riders {
            flockNodes.append(FlockNode(
                riderId: rider.id,
                riderName: rider.name,
                locationString: rider.location,
                capacity: rider.passengerCapacity,
                isDriver: rider.isDriver && !trip.useSuggestedDrivers
            ))
        }
        flockNodes.append(FlockNode(
            riderId: trip.destinationCacheID,
            riderName: "Destination",
            locationString: trip.destination,
            capacity: 1,
            isDestination: true
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
            guard let _ = prospect.route else { return false }
        }
        return true
    }
    
    func optimizeRoutes() -> Void {
        if !OptimizedTripCache.hasTripChanged(trip) {
            guard let uCacheItem = OptimizedTripCache.get(trip.id) else { return }
            self.routeStack = uCacheItem.routeStack
            OptimizedTrip.queue = []
            return
        }
        let context = OptimizationContext(type: trip.useSuggestedDrivers ? .suggested : .specified)
        optimizeRoutesWithContext(context: context)
    }
    
    
    func optimizeRoutesWithContext(context: OptimizationContext) -> Void {
        
        // create map with the node as the key and collections of routes from and to the node as the value
        var nodeRouteMap: [FlockNode:NodeSpecificRouteCollections] = [:]
        for node in allNodes {
            let routesFrom: [FlockRoute] = routeProspects.filter({$0.from.riderId == node.riderId})
            let routesTo: [FlockRoute] = routeProspects.filter({$0.to.riderId == node.riderId})
            nodeRouteMap[node] = NodeSpecificRouteCollections(from: routesFrom, to: routesTo)
        }
        var newRouteStack: [FlockRoute] = []
        var newSuggestedDriverIds: [UUID] = []
        var newRouteStackTotalDistance: Double = Double.greatestFiniteMagnitude
        var allTripProspectCollections: [TripProspectCollection] = []
        
        // for each node create collection of every possible path a node can take when assumed as the driver
        for node in allNodes {
            if !context.isSpecifiedType() || node.isDriver {
                let tripProspects = createTripProspectsForAssumedDriver(driver: node, nodeRouteMap: nodeRouteMap)
                allTripProspectCollections.append(TripProspectCollection(node: node, tripProspects: tripProspects))
            }
        }
        
        let allNodeIds: Set<UUID> = Set(allNodes.map({$0.riderId!}))
        
        // for each collection per node
        for tripProspectCollection in allTripProspectCollections {
            let node = tripProspectCollection.node
            let tripProspects = tripProspectCollection.tripProspects
            
            // for each prospect (collection of routes, regardless of completeness)
            for tripProspect in tripProspects {
                let nodesAccountedFor = tripProspect.nodesAccountedFor
                let routes = tripProspect.routes

                // if prospect is already complete, compare and set as shortest
                if SetUtility.isSetComplete(set: nodesAccountedFor, referenceSet: allNodeIds, exception: trip.destinationCacheID) {
                    
                    // we can only use a complete trip in .specified context if there is only 1 specified driver
                    if !context.isSpecifiedType() || trip.drivers == 1 {
                        if tripProspect.totalDistance < newRouteStackTotalDistance {
                            for route in routes {
                                route.setDriver(node)
                            }
                            newRouteStack = routes
                            newRouteStackTotalDistance = tripProspect.totalDistance
                            newSuggestedDriverIds = [node.riderId!]
                        }
                    }
                }
                else {
                    var theTripProspectCollections: [TripProspectCollection] = []
                    var theNodesAccountedFor: Set<UUID> = Set()
                    theTripProspectCollections.append(TripProspectCollection(node: node, tripProspects:[tripProspect]))
                    for val in nodesAccountedFor { theNodesAccountedFor.insert(val) }
                    addToTripProspectCollection(
                        allTripProspectCollections: allTripProspectCollections,
                        theTripProspectCollections: &theTripProspectCollections,
                        theNodesAccountedFor: &theNodesAccountedFor,
                        allNodeIds: allNodeIds
                    )
                    if SetUtility.isSetComplete(set: theNodesAccountedFor, referenceSet: allNodeIds, exception: trip.destinationCacheID) {
                        var totalCombinedDistance: Double = 0
                        var newCombinedRouteStack: [FlockRoute] = []
                        var combinedSuggestedDriverIds: [UUID] = []
                        var totalDrivers: Int = 0
                        for tripProspectCollection in theTripProspectCollections {
                            totalDrivers += 1
                            combinedSuggestedDriverIds.append(tripProspectCollection.node.riderId!)
                            for tripProspect in tripProspectCollection.tripProspects {
                                totalCombinedDistance += tripProspect.totalDistance
                                for route in tripProspect.routes {
                                    route.setProposedDriver(tripProspectCollection.node)
                                }
                                newCombinedRouteStack.append(contentsOf: tripProspect.routes)
                            }
                        }
                        // in .specified driver context only consider if total # of drivers match
                        if !context.isSpecifiedType() || totalDrivers == trip.drivers {
                            if totalCombinedDistance < newRouteStackTotalDistance {
                                for route in newCombinedRouteStack {
                                    route.setDriver(route.proposedDriver)
                                }
                                newRouteStack = newCombinedRouteStack
                                newRouteStackTotalDistance = totalCombinedDistance
                                newSuggestedDriverIds = combinedSuggestedDriverIds
                            }
                        }
                    }
                    
                }
            }
        }
        
        self.routeStack = newRouteStack
        // set driver based on optimized route suggestion
        if self.routeStack.count > 0 {
            self.suggestedDriverIds = newSuggestedDriverIds
        }
        OptimizedTrip.queue = []
//        printTripString()
    }
    
    // given a set of trip 'snippets' go through all other snippets recursively to find combinations that make a 'complete' trip
    func addToTripProspectCollection(allTripProspectCollections: [TripProspectCollection], theTripProspectCollections: inout [TripProspectCollection], theNodesAccountedFor: inout Set<UUID>, allNodeIds: Set<UUID>) -> Void {
        for tripProspectCollection in allTripProspectCollections {
            if tripProspectCollectionsContainsNode(tripProspectCollections: theTripProspectCollections, node: tripProspectCollection.node) {
               continue
            }
            for tripProspect in tripProspectCollection.tripProspects {
                let nodesAccountedFor = tripProspect.nodesAccountedFor
                
                if SetUtility.doSetsOverlap(set1: nodesAccountedFor, set2: theNodesAccountedFor, exception: trip.destinationCacheID) {
                    continue
                }
                
                let newTripProspectCollection = TripProspectCollection(node: tripProspectCollection.node, tripProspects: [tripProspect])
                theTripProspectCollections.append(newTripProspectCollection)
                for val in nodesAccountedFor { theNodesAccountedFor.insert(val) }
                
                if SetUtility.areSetsComplete(set1: nodesAccountedFor, set2: theNodesAccountedFor, referenceSet: allNodeIds, exception: trip.destinationCacheID) {
                    return
                }
                else {
                    addToTripProspectCollection(
                        allTripProspectCollections: allTripProspectCollections,
                        theTripProspectCollections: &theTripProspectCollections,
                        theNodesAccountedFor: &theNodesAccountedFor,
                        allNodeIds: allNodeIds
                    )
                }
            }
        }
    }
    
    func tripProspectCollectionsContainsNode(tripProspectCollections: [TripProspectCollection], node: FlockNode) -> Bool {
        for tripProspectCollection in tripProspectCollections {
            if tripProspectCollection.node.riderId! == node.riderId! {
                return true
            }
            for tripProspect in tripProspectCollection.tripProspects {
                if tripProspect.nodesAccountedFor.contains(node.riderId!) {
                    return true
                }
            }
        }
        return false
    }
    
    // entry point for creating prospects for a starting node
    func createTripProspectsForAssumedDriver(driver: FlockNode, nodeRouteMap: [FlockNode:NodeSpecificRouteCollections]) -> [TripProspect] {
        var tripProspects: [TripProspect] = []
        
        // get routes from assumed driver
        let routesFrom: [FlockRoute] = nodeRouteMap[driver]!.from
        for routeFrom in routesFrom {
            var nodesAccountedFor: Set<UUID> = Set()
            nodesAccountedFor.insert(driver.riderId!)
            let childProspects = addToProspectForNode(
                node: routeFrom.to,
                nodeRouteMap: nodeRouteMap,
                nodesAccountedFor: &nodesAccountedFor
            )
            nodesAccountedFor.insert(trip.destinationCacheID)
            if childProspects.count == 0 {
                let combinedChildProspects: [FlockRoute] = [routeFrom]
                let localNodesAccountedFor: Set<UUID> = [driver.riderId!, trip.destinationCacheID]
                tripProspects.append(TripProspect(nodesAccountedFor: localNodesAccountedFor, routes: combinedChildProspects))
            }
            for childProspect in childProspects {
                var combinedChildProspects: [FlockRoute] = [routeFrom]
                combinedChildProspects.append(contentsOf: childProspect)
                var localNodesAccountedFor: Set<UUID> = Set()
                for flockRoute in combinedChildProspects {
                    localNodesAccountedFor.insert(flockRoute.from.riderId!)
                    localNodesAccountedFor.insert(flockRoute.to.riderId!)
                }
                // only add the prospect if its less than or equal to capacity
                if combinedChildProspects.count <= driver.capacity {
                    tripProspects.append(TripProspect(nodesAccountedFor: localNodesAccountedFor, routes: combinedChildProspects))
                }
            }
        }
        return tripProspects
    }
    
    // recursively called as we traverse nodes to create prospects for assumed drivers
    // go 'to' next node, then for each route going from that node, go 'to' each and continue while collecting routes
    func addToProspectForNode(node: FlockNode, nodeRouteMap: [FlockNode:NodeSpecificRouteCollections], nodesAccountedFor: inout Set<UUID>) -> [[FlockRoute]] {
        var nodeLocalProspects: [[FlockRoute]] = []
        if node.isDestination {
            return nodeLocalProspects
        }
        let routesFrom: [FlockRoute] = nodeRouteMap[node]!.from
        for routeFrom in routesFrom {
            // if we're not going back to where we came from
            if !nodesAccountedFor.contains(routeFrom.to.riderId!) {
                nodesAccountedFor.insert(node.riderId!)
                let childProspects = addToProspectForNode(
                    node: routeFrom.to,
                    nodeRouteMap: nodeRouteMap,
                    nodesAccountedFor: &nodesAccountedFor
                )
                if childProspects.count == 0 {
                    let combinedChildProspects: [FlockRoute] = [routeFrom]
                    nodeLocalProspects.append(combinedChildProspects)
                }
                for childProspect in childProspects {
                    var combinedChildProspects: [FlockRoute] = [routeFrom]
                    combinedChildProspects.append(contentsOf: childProspect)
                    nodeLocalProspects.append(combinedChildProspects)
                }
            }
        }
        return nodeLocalProspects
    }
    
    func printTripString() -> Void {
        var tripString: String = ""
        for i in 0..<self.routeStack.count {
            let route = self.routeStack[i]
            if i == self.routeStack.count-1 {
                tripString += (self.suggestedDriverIds.contains(route.from.riderId!) ? "^" : "") + route.from.riderName + " -> " + route.to.riderName
            }
            else {
                tripString += (self.suggestedDriverIds.contains(route.from.riderId!) ? "^" : "") + route.from.riderName + " -> "
            }
        }
        print(tripString)
    }
    
    static func == (lhs: OptimizedTrip, rhs: OptimizedTrip) -> Bool {
        if lhs.routeStack.count != rhs.routeStack.count {
            return false
        }
        for route in lhs.routeStack {
            if !rhs.routeStack.contains(route) {
                return false
            }
        }
        for route in rhs.routeStack {
            if !lhs.routeStack.contains(route) {
                return false
            }
        }
        return true
    }
}

// a trip 'prospect' is any combination of routes that can happen from a node
// ex. 1-->3-->2 or 1-->Destination or 2-->3, etc.
// prospects will get collected per node and optimizeRoutes will match and add up
// prospects from various nodes to make a complete trip
struct TripProspect {
    var nodesAccountedFor: Set<UUID> = Set()
    var routes: [FlockRoute] = []
    var totalDistance: Double {
        var distance: Double = 0
        for route in routes {
//            distance += route.distance
            distance += route.route?.expectedTravelTime ?? 0
        }
        return distance
    }
}

// for each node collect all the different prospects that could possibly make a complete trip
struct TripProspectCollection {
    var node: FlockNode
    var tripProspects: [TripProspect]
}

struct NodeSpecificRouteCollections {
    var from: [FlockRoute]
    var to: [FlockRoute]
}

struct OptimizationRequest {
    
}
