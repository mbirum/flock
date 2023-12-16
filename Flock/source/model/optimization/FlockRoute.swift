
import Foundation
import MapKit

class FlockRoute: NSObject {
    @objc var from: FlockNode
    @objc var to: FlockNode
    var fromObservation: NSKeyValueObservation?
    var toObservation: NSKeyValueObservation?
    
    @objc dynamic var route: MKRoute? = nil
    
    var distance: Double {
        guard let uRoute = route else { return 0 }
        return uRoute.distance
    }
    
    init(from: FlockNode, to: FlockNode) {
        self.from = from
        self.to = to
        super.init()
        fromObservation = observe(\.from.pin, options: [.old, .new]) { object, change in
            guard let _ = from.pin else { return }
            self.calculateRoute()
        }
        toObservation = observe(\.to.pin, options: [.old, .new]) { object, change in
            guard let _ = to.pin else { return }
            self.calculateRoute()
        }
        calculateRoute()
    }
    
    func calculateRoute() -> Void {
        guard let uFromPin = from.pin, let uToPin = to.pin else { return }
        print("calculating route for \(from.riderName) to \(to.riderName)")
        LocationSearchService.calculateRoute(
            source: uFromPin,
            destination: uToPin,
            routeHandler: { source, destination, route in
                self.route = route
            }
        )
    }
}
