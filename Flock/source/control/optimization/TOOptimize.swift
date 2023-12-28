
extension TripOptimizer {
    
    static func optimizeRoutes() -> Void {
        guard let request = TripOptimizer.queue.getNext() else { return }
        let trip = request.trip
        if !OptimizedTripCache.hasTripChanged(trip) {
            useCachedOptimizedTrip()
            return
        }
        optimizeRoutesWithContext(
            context: OptimizationContext(type: trip.useSuggestedDrivers ? .suggested : .specified)
        )
    }
    
    static func optimizeRoutesWithContext(context: OptimizationContext) -> Void {
        guard let request = TripOptimizer.queue.getNext() else { return }
        let nodeMap = request.nodeMap
        
        // get all variations for assumed drivers
        var allVariations: [TripVariation] = []
        for node in nodeMap.keys {
            if (!context.isSpecifiedType() || node.isDriver) && !node.isDestination {
                allVariations.append(contentsOf: findVariationsForAssumedDriver(driver: node))
            }
        }
        
        // find and set fastest trip
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
    
}
