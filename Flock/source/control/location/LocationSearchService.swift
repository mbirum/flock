
import Foundation
import SwiftUI
import MapKit
import Combine

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    var completer: MKLocalSearchCompleter
    var cancellable: AnyCancellable?
    @Published var searchQuery = ""
    @Published var completions: [MKLocalSearchCompletion] = []
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        cancellable = $searchQuery.assign(to: \.queryFragment, on: self.completer)
        completer.delegate = self
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
    }
    
    static func translateLocationToMapItem(location: String, mapItemHandler: @escaping (_ item: MKMapItem) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = location
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response else { return }
            guard let item = response.mapItems.first else { return }
            mapItemHandler(item)
        }
    }
    
    static func calculateRoute(source: MKMapItem, destination: MKMapItem, routeHandler: @escaping (_ source: MKMapItem, _ destination: MKMapItem, _ route: MKRoute) -> Void) {
        guard let uSourceTitle = source.placemark.title, let uDestinationTitle = destination.placemark.title else {
            return calculateNewRoute(source: source, destination: destination, routeHandler: routeHandler)
        }
        if RouteCache.isRouteCached(source: uSourceTitle, destination: uDestinationTitle) {
            let key: RouteCacheKey = RouteCacheKey(source: uSourceTitle, destination: uDestinationTitle)
            guard let routeCacheItem: RouteCacheItem = RouteCache.get(key) else { return }
            routeHandler(source, destination, routeCacheItem.route)
            return
        }
        return calculateNewRoute(source: source, destination: destination, routeHandler: routeHandler)
        
    }
    
    static func calculateNewRoute(source: MKMapItem, destination: MKMapItem, routeHandler: @escaping (_ source: MKMapItem, _ destination: MKMapItem, _ route: MKRoute) -> Void) {

        let directions = MKDirections(
            request: MKDirections.RequestWith(source, destination)
        )
        
        directions.calculate { response, error in
            guard let uResponse = response else { return }
            if uResponse.routes.count > 0 {
                var theRoute: MKRoute = uResponse.routes.first!
                for route in uResponse.routes {
                    if route.expectedTravelTime < theRoute.expectedTravelTime {
                        theRoute = route
                    }
                }
                routeHandler(source, destination, theRoute)
                guard let uSourceTitle = source.placemark.title, 
                        let uDestinationTitle = destination.placemark.title else { return }
                RouteCache.put(
                    key: RouteCacheKey(source: uSourceTitle, destination: uDestinationTitle),
                    route: theRoute
                )
            }
        }
    }
    
}

extension MKLocalSearchCompletion: Identifiable {}

extension MKDirections {
    static func RequestWith(_ source: MKMapItem, _ destination: MKMapItem) -> MKDirections.Request {
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        return request
    }
}
