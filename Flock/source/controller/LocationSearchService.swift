
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
        search.start { (response, error) in
            guard let response = response else {return}
            guard let item = response.mapItems.first else {return}
            mapItemHandler(item)
//            item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
            
        }
    }
    
    static func calculateRoute(source: MKMapItem, destination: MKMapItem, routeHandler: @escaping (_ source: MKMapItem, _ destination: MKMapItem, _ route: MKRoute) -> Void) {
        let request = MKDirections.Request()
        request.source = source
        request.destination = destination
        request.requestsAlternateRoutes = true
        request.transportType = .automobile

        let directions = MKDirections(request: request)

        directions.calculate {
            response, error in
            guard let unwrappedResponse = response else { return }
            if let route = unwrappedResponse.routes.first {
                routeHandler(source, destination, route)
            }
        }
    }
    
    static func calculateRoute(sourceLocation: String, destinationLocation: String, routeHandler: @escaping (_ source: MKMapItem, _ destination: MKMapItem, _ route: MKRoute) -> Void) {
        
        // translate source
        LocationSearchService.translateLocationToMapItem(
            location: sourceLocation,
            mapItemHandler: { source in
                
                // translate destination
                LocationSearchService.translateLocationToMapItem(
                    location: destinationLocation,
                    mapItemHandler: { destination in
                        let request = MKDirections.Request()
                        request.source = source
                        request.destination = destination
                        request.requestsAlternateRoutes = true
                        request.transportType = .automobile

                        let directions = MKDirections(request: request)

                        directions.calculate {
                            response, error in
                            guard let unwrappedResponse = response else { return }
                            if let route = unwrappedResponse.routes.first {
                                routeHandler(source, destination, route)
                            }
                        }
                    }
                )
            }
        )
    }
    
    static func calculateRoute(trip: Trip, routeHandler: @escaping (_ source: MKMapItem, _ destination: MKMapItem, _ route: MKRoute) -> Void) {
        var sourceLocation: String? = nil
        for rider in trip.riders {
            if rider.isDriver {
                sourceLocation = rider.location
                break
            }
        }
        guard let sourceLocation else { return }
        calculateRoute(sourceLocation: sourceLocation, destinationLocation: trip.destination, routeHandler: routeHandler)
    }
    
}

extension MKLocalSearchCompletion: Identifiable {}
