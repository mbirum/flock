
class TripOptimizer {
    static var queue = OptimizationRequestQueue()
    
    static func optimize(_ trip: Trip) -> Void {
        guard isFree() else { return }
        queue.add(OptimizationRequest(trip))
        requestRoutes()
    }

}
