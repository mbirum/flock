
import Foundation
import MapKit

class FlockRoute: NSObject {
    var id: UUID = UUID()
    @objc var from: FlockNode
    @objc var to: FlockNode
    var driver: FlockNode
    var proposedDriver: FlockNode
    var fromObservation: NSKeyValueObservation?
    var toObservation: NSKeyValueObservation?
    
    @objc dynamic var route: MKRoute? = nil
    
    var distance: Double {
        guard let uRoute = route else { return 0 }
//        return uRoute.distance
        return uRoute.expectedTravelTime
    }
    
    func initializeObservations() -> Void {
        fromObservation = observe(\.from.pin, options: [.old, .new]) { object, change in
            guard let _ = self.from.pin else { return }
            self.calculateRoute()
        }
        toObservation = observe(\.to.pin, options: [.old, .new]) { object, change in
            guard let _ = self.to.pin else { return }
            self.calculateRoute()
        }
    }
    
    init(from: FlockNode, to: FlockNode) {
        self.from = from
        self.to = to
        self.driver = from
        self.proposedDriver = from
        super.init()
        initializeObservations()
        calculateRoute()
    }
    
    init(from: FlockNode, to: FlockNode, driver: FlockNode) {
        self.from = from
        self.to = to
        self.driver = driver
        self.proposedDriver = from
        super.init()
        initializeObservations()
        calculateRoute()
    }
    
    func setDriver(_ driver: FlockNode) -> Void {
        self.driver = driver
    }
    
    func setProposedDriver(_ driver: FlockNode) -> Void {
        self.proposedDriver = driver
    }
    
    func calculateRoute() -> Void {
        guard let uFromPin = from.pin, let uToPin = to.pin else { return }
        LocationSearchService.calculateRoute(
            source: uFromPin,
            destination: uToPin,
            routeHandler: { source, destination, route in
                self.route = route
            }
        )
    }
}
