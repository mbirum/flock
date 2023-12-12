
import Foundation
import MapKit

class OptimizedTrip {
    var trip: Trip {
        didSet {
            self.calculateRoutes()
        }
    }
    
    var routeStack: [FlockRoute] = []
    
    init(_ trip: Trip) {
        self.trip = trip
        calculateRoutes()
    }
    
    func calculateRoutes() -> Void {
        var driver: Rider? = nil
        var passengerNodes: [FlockNode] = []
        for rider in trip.riders {
            if rider.isDriver {
                driver = rider
            }
            else {
                passengerNodes.append(FlockNode(rider.location, annotationType: "pickup"))
            }
        }
        guard let unwrappedDriver = driver else { return }
        var newRouteStack: [FlockRoute] = []
        let startNode: FlockNode = FlockNode(unwrappedDriver.location, annotationType: "source")
        let destinationNode: FlockNode = FlockNode(trip.destination, annotationType: "destination")
        for i in 0..<passengerNodes.count {
            if i == 0 {
                let newRoute: FlockRoute = FlockRoute(from: startNode, to: passengerNodes[i])
                newRouteStack.append(newRoute)
            }
            else {
                let newRoute: FlockRoute = FlockRoute(from: passengerNodes[i-1], to: passengerNodes[i])
                newRouteStack.append(newRoute)
            }
        }
        if passengerNodes.count > 0 {
            let finalRoute: FlockRoute = FlockRoute(from: passengerNodes[passengerNodes.count-1], to: destinationNode)
            newRouteStack.append(finalRoute)
        }
        else {
            let finalRoute: FlockRoute = FlockRoute(from: startNode, to: destinationNode)
            newRouteStack.append(finalRoute)
        }
        self.routeStack = newRouteStack
    }
}

