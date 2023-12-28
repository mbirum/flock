
import mbutils

extension TripOptimizer {
    
    // The request is ready if the # of 'optimized' routes = expected # of routes
    // AND each optimized route has an MKRoute, from.pin, and to.pin set
    static func isRequestComplete() -> Bool {
        guard let request = TripOptimizer.queue.getNext() else { return false }
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
        guard let request = TripOptimizer.queue.getNext() else { return nil }
        guard isRequestComplete() else { return nil }
        guard let uOptimizedTrip = request.optimizedTrip else { return nil }
        return uOptimizedTrip
    }
    
    
    static func useCachedOptimizedTrip() -> Void {
        guard let request = TripOptimizer.queue.getNext() else { return }
        guard let uCacheItem = OptimizedTripCache.get(request.trip.id) else { return }
        let optimizedTrip = uCacheItem.optimizedTrip
        request.optimizedTrip = optimizedTrip
    }
    
    static func startRouteRequestChecker() -> Void {
        TimerBasedConditionCheck.create(condition: {
            return areRouteRequestsComplete()
        }, complete: {
            optimizeRoutes()
        })
    }
    
    static func areRouteRequestsComplete() -> Bool {
        guard let request = TripOptimizer.queue.getNext() else { return false }
        for flockRoute in request.flockRoutes {
            guard let _ = flockRoute.route else { return false }
        }
        return true
    }
    
    static func isFree() -> Bool {
        return TripOptimizer.queue.isEmpty()
    }
    
    static func clearQueue() -> Void {
        return TripOptimizer.queue.clear()
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
