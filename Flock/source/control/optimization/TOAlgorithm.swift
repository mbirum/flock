
extension TripOptimizer {
    
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
        guard let request = TripOptimizer.queue.getNext() else { return }
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
        guard let request = TripOptimizer.queue.getNext() else { return }
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
}
