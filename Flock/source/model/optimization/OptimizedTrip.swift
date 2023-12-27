
import Foundation

class OptimizedTrip {
    var originalTrip: Trip?
    var tripVariations: [TripVariation] = []
    var totalTime: Double = Double.greatestFiniteMagnitude
    
    init(originalTrip: Trip, tripVariations: [TripVariation]) {
        self.tripVariations = tripVariations
        self.originalTrip = originalTrip
        self.setTotalTime()
    }
    
    init() {
        self.tripVariations = []
    }
    
    func setTotalTime() -> Void {
        var totalTime: Double = 0
        for tripVariation in tripVariations {
            totalTime += tripVariation.totalTime
        }
        self.totalTime = totalTime
    }
    
    init(_ tripVariations: [TripVariation]) {
        self.tripVariations = tripVariations
    }
    
    func setDrivers() -> Void {
        for variation in tripVariations {
            variation.setDriver()
        }
    }
    
    func isComplete() -> Bool {
        guard let uOriginalTrip = originalTrip else { return false }
        
        // each rider needs to be accounted for
        for rider in uOriginalTrip.riders {
            var found = false
            forVariation: for tripVariation in tripVariations {
                forRoute: for route in tripVariation.routes {
                    if route.from.riderId == rider.id {
                        found = true
                        break forVariation
                    }
                }
            }
            if !found {
                return false
            }
        }
        
        // nodes cant be shared across variations
        for i in 0..<tripVariations.count {
            let variation = tripVariations[i]
            for node in variation.allNodes {
                if node.isDestination {
                    continue
                }
                for ii in 0..<tripVariations.count {
                    if ii == i {
                        continue
                    }
                    let otherVariation = tripVariations[ii]
                    if otherVariation.contains(node) {
                        return false
                    }
                }
            }
        }
        
        return true
    }
}
