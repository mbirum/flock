
extension TripOptimizer {
    
    static func requestRoutes() -> Void {
        guard let request = TripOptimizer.queue.getNext() else { return }
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
    
}
