
import Foundation
import mbutils

class TripOptimizer {
    static var queue = OptimizationRequestQueue()
    
    static func isFree() -> Bool {
        return queue.isEmpty()
    }
    
    // The request is ready if the # of 'optimized' routes = expected # of routes
    // AND each optimized route has a route, from.pin, and to.pin set
    static func isRequestComplete() -> Bool {
        guard let request = queue.getNext() else { return false }
        guard let uOptimizedTrip = request.optimizedTrip else { return false }
        let trip = request.trip
        let tripVariations = uOptimizedTrip.tripVariations
        var count = 0
        for tripVariation in tripVariations {
            count += tripVariation.routes.count
        }
        if count < (trip.riders.count) {
            return false
        }
        for tripVariation in tripVariations {
            for flockRoute in tripVariation.routes {
                guard let _ = flockRoute.route, let _ = flockRoute.from.pin, let _ = flockRoute.to.pin else {
                    return false
                }
            }
        }
        return true
    }
    
    static func getOptimizedTrip() -> OptimizedTrip? {
        guard let request = queue.getNext() else { return nil }
        guard isRequestComplete() else { return nil }
        guard let uOptimizedTrip = request.optimizedTrip else { return nil }
        return uOptimizedTrip
    }
    
    static func optimize(_ trip: Trip) -> Void {
        guard isFree() else { return }
        queue.add(OptimizationRequest(trip))
        requestRoutes()
    }
    
    static func useCachedOptimizedTrip() -> Void {
        guard let request = queue.getNext() else { return }
        guard let uCacheItem = OptimizedTripCache.get(request.trip.id) else { return }
        let optimizedTrip = uCacheItem.optimizedTrip
        request.optimizedTrip = optimizedTrip
    }
    
    static func requestRoutes() -> Void {
        guard let request = queue.getNext() else { return }
        let trip = request.trip
        
        if !OptimizedTripCache.hasTripChanged(trip) {
            useCachedOptimizedTrip()
            return
        }
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
        
        for i in 0..<flockNodes.count {
            if !flockNodes[i].isDestination {
                for ii in 0..<flockNodes.count {
                    if i != ii {
                        request.flockRoutes.append(FlockRoute(from: flockNodes[i], to: flockNodes[ii]))
                    }
                }
            }
        }
        
        startRouteRequestChecker()
    }
    
    static func startRouteRequestChecker() -> Void {
        TimerBasedConditionCheck.create(condition: {
            return areRouteRequestsComplete()
        }, complete: {
            optimizeRoutes()
        })
    }
    
    static func areRouteRequestsComplete() -> Bool {
        guard let request = queue.getNext() else { return false }
        for flockRoute in request.flockRoutes {
            guard let _ = flockRoute.route else { return false }
        }
        return true
    }
    
    static func optimizeRoutes() -> Void {
        guard let request = queue.getNext() else { return }
        let trip = request.trip
        if !OptimizedTripCache.hasTripChanged(trip) {
            useCachedOptimizedTrip()
            return
        }
        let context = OptimizationContext(type: trip.useSuggestedDrivers ? .suggested : .specified)
        optimizeRoutesWithContext(context: context)
    }
    
    static func optimizeRoutesWithContext(context: OptimizationContext) -> Void {
        guard let request = queue.getNext() else { return }
        let nodeMap = request.nodeMap
        
        // get all variations for assumed drivers
        var allVariations: [TripVariation] = []
        for node in nodeMap.keys {
            if (!context.isSpecifiedType() || node.isDriver) && !node.isDestination {
                allVariations.append(contentsOf: findVariationsForAssumedDriver(driver: node))
            }
        }
        
        var fastestTrip = OptimizedTrip()
        for variation in allVariations {
            let optimizedTrips = findOptimizedTripsForVariation(variation: variation, allVariations: allVariations)
            for optimizedTrip in optimizedTrips {
                if !context.isSpecifiedType() || optimizedTrip.tripVariations.count == request.trip.drivers {
                    if optimizedTrip.totalTime < fastestTrip.totalTime {
                        fastestTrip = optimizedTrip
                    }
                }
            }
        }
        request.optimizedTrip = fastestTrip
    }
    
    //@entry @create
    static func findVariationsForAssumedDriver(driver: FlockNode) -> [TripVariation] {
        var variations: [TripVariation] = []
        completeVariationsForAssumedDriver(
            currentNode: driver,
            precedingVariation: TripVariation(),
            completeVariations: &variations
        )
        return variations
    }
    
    //@recursive @create
    static func completeVariationsForAssumedDriver(currentNode: FlockNode, precedingVariation: TripVariation, completeVariations: inout [TripVariation]) -> Void {
        guard let request = queue.getNext() else { return }
        if currentNode.isDestination {
            let completeVariation = TripVariation(routes: precedingVariation.routes)
            guard let driver = completeVariation.driver else { return }
            if completeVariation.routes.count <= driver.capacity {
                completeVariations.append(completeVariation)
            }
            return
        }
        let routesFrom = request.nodeMap[currentNode] ?? []
        for route in routesFrom {
            if precedingVariation.contains(route.to) {
                continue
            }
            let newPrecedingVariation = TripVariation(routes: precedingVariation.routes)
            newPrecedingVariation.routes.append(route)
            completeVariationsForAssumedDriver(
                currentNode: route.to,
                precedingVariation: newPrecedingVariation,
                completeVariations: &completeVariations
            )
        }
    }
    
    //@entry @optimize
    static func findOptimizedTripsForVariation(variation: TripVariation, allVariations: [TripVariation]) -> [OptimizedTrip] {
        var trips: [OptimizedTrip] = []
        completeOptimizedTripsForVariation(
            allVariations: allVariations,
            currentVariations: [variation],
            completeTrips: &trips
        )
        return trips
    }
    
    //@recursive @optimize
    static func completeOptimizedTripsForVariation(allVariations: [TripVariation], currentVariations: [TripVariation], completeTrips: inout [OptimizedTrip]) -> Void {
        guard let request = queue.getNext() else { return }
        let currentOptimizedTrip = OptimizedTrip(originalTrip: request.trip, tripVariations: currentVariations)
        if currentOptimizedTrip.isComplete() {
            completeTrips.append(currentOptimizedTrip)
            return
        }
        for variation in allVariations {
            if currentVariations.contains(variation) ||
                variation.isOverlappingWithOthers(others: currentVariations) {
                continue
            }
            var newVariations: [TripVariation] = []
            newVariations.append(contentsOf: currentVariations)
            newVariations.append(variation)
            completeOptimizedTripsForVariation(
                allVariations: allVariations,
                currentVariations: newVariations,
                completeTrips: &completeTrips
            )
        }
    }
    
    static func printTripVariation(_ variation: TripVariation) -> Void {
        var tripString: String = ""
        for i in 0..<variation.routes.count {
            let route = variation.routes[i]
            if i == variation.routes.count-1 {
                tripString += route.from.riderName + " -> " + route.to.riderName
            }
            else {
                tripString += route.from.riderName + " -> "
            }
        }
        print(tripString)
    }
}
