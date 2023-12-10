
import SwiftUI
import MapKit

struct TripMapView: View {
    @Binding var sourceLocationString: String
    @Binding var destinationLocationString: String
    @State var routeSourcePin: MKMapItem? = DefaultMapKitLocation.pin
    @State var routeDestinationPin: MKMapItem? = DefaultMapKitLocation.pin
    @State var route: MKRoute? = nil
    
    var body: some View {
        RouteMapViewRepresentable(
            route: $route,
            routeSourcePin: $routeSourcePin,
            routeDestinationPin: $routeDestinationPin
        )
        .onAppear(perform: {
            calculateRoute(sourceLocationString, destinationLocationString)
        })
        .onChange(of: sourceLocationString) { oldValue, newValue in
            calculateRoute(newValue, destinationLocationString)
        }
        .onChange(of: destinationLocationString) { oldValue, newValue in
            calculateRoute(sourceLocationString, newValue)
        }
    }
    
    func calculateRoute(_ sourceLocationString: String, _ destinationLocationString: String) -> Void {
        LocationSearchService.calculateRoute(
            sourceLocation: sourceLocationString,
            destinationLocation: destinationLocationString,
            routeHandler: { source, destination, route in
                self.routeSourcePin = source
                self.routeDestinationPin = destination
                self.route = route
            }
        )
    }
}

struct RouteMapViewRepresentable: UIViewRepresentable {
    
    @Binding var route: MKRoute?
    @Binding var routeSourcePin: MKMapItem?
    @Binding var routeDestinationPin: MKMapItem?
    
    var mapViewDelegate: RouteMapViewDelegate = RouteMapViewDelegate()
    
    func getRegion() -> MKCoordinateRegion {
        guard let unwrappedRouteSourcePin = routeSourcePin else {
            return DefaultMapKitLocation.region
        }
        return MKCoordinateRegion(
            center: unwrappedRouteSourcePin.placemark.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.17,
                longitudeDelta: 0.17
            )
        )
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        for annotation in view.annotations {
            view.removeAnnotation(annotation)
        }
        for overlay in view.overlays {
            view.removeOverlay(overlay)
        }
        view.delegate = mapViewDelegate
        view.setRegion(getRegion(), animated: true)
        
        guard let unwrappedRoute = route,
                let unwrappedRouteSourcePin = routeSourcePin,
                let unwrappedRouteDestinationPin = routeDestinationPin
        else {
            return
        }
        
        view.addOverlay(unwrappedRoute.polyline)
        view.addAnnotation(MKPointAnnotation(__coordinate: unwrappedRouteSourcePin.placemark.coordinate))
        view.addAnnotation(MKPointAnnotation(__coordinate: unwrappedRouteDestinationPin.placemark.coordinate))
        view.setVisibleMapRect(unwrappedRoute.polyline.boundingMapRect, edgePadding: UIEdgeInsets.init(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        updateUIView(mapView, context: context)
        return mapView
    }
    
}

class RouteMapViewDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.systemIndigo
        renderer.lineWidth = 5.0
        return renderer
    }
}
