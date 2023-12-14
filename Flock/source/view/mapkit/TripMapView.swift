
import SwiftUI
import MapKit
import mbutils

struct TripMapView: View {
    @Binding var trip: Trip
    @State var loadOverlayPresent: Bool = false
    @State var invalidateView: Bool = false
    @State var optimizedTrip: OptimizedTrip? = nil
    
    var body: some View {
        ZStack {
            
            TripMapViewRepresentable(
                invalidateView: $invalidateView,
                optimizedTrip: $optimizedTrip
            )
            .onAppear(perform: {
                self.optimizedTrip = OptimizedTrip(trip)
                startOptimizedTripChecker()
            })
            .onChange(of: trip) { oldValue, newValue in
                self.optimizedTrip = OptimizedTrip(newValue)
                startOptimizedTripChecker()
            }
            if loadOverlayPresent {
                ProgressView()
            }
        }
    }
    
    // Since route calculation requests are async, start an interval timer that
    // checks to see if requests are finished. Invalidate inner view when complete
    func startOptimizedTripChecker() -> Void {
        loadOverlayPresent = true
        TimerBasedConditionCheck.create(condition: {
            return self.isOptimizedTripReady(self.optimizedTrip!)
        }, complete: {
            if trip.useSuggestedDrivers {
                setNewSuggestedDriver()
            }
            invalidateView.toggle()
            loadOverlayPresent = false
        })
    }
    
    func setNewSuggestedDriver() -> Void {
        guard let unwrappedSuggestedDriverId = optimizedTrip?.suggestedDriverId else { return }
        for rider in $trip.riders {
            if rider.id == unwrappedSuggestedDriverId {
                rider.wrappedValue.isDriver = true
            }
            else {
                rider.wrappedValue.isDriver = false
            }
        }
    }
    
    // The trip is ready if the # of 'optimized' routes = expected # of routes
    // AND each optimized route has a route, from.pin, and to.pin set
    func isOptimizedTripReady(_ optimizedTrip: OptimizedTrip) -> Bool {
        if optimizedTrip.routeStack.count < (optimizedTrip.trip.passengers + 1) {
            return false
        }
        for flockRoute in optimizedTrip.routeStack {
            guard let _ = flockRoute.route, let _ = flockRoute.from.pin, let _ = flockRoute.to.pin else {
                return false
            }
        }
        return true
    }
    
}




// inner MapKit 'representable' view
struct TripMapViewRepresentable: UIViewRepresentable {
    
    @Binding var invalidateView: Bool
    @Binding var optimizedTrip: OptimizedTrip?
    
    var mapViewDelegate: MapViewDelegate = MapViewDelegate()
    
    func getRegion() -> MKCoordinateRegion {
        return DefaultMapKitLocation.region
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
        view.setVisibleMapRect(DefaultMapKitLocation.rect, edgePadding: UIEdgeInsets.init(top: 100.0, left: 50.0, bottom: 100.0, right: 50.0), animated: true)
        
        guard let unwrappedOptimizedTrip = optimizedTrip else { return }
        
        var minX: Double = Double.greatestFiniteMagnitude, minY: Double = Double.greatestFiniteMagnitude
        var width: Double = 0, height: Double = 0
        for flockRoute in unwrappedOptimizedTrip.routeStack {
            guard let unwrappedFlockRoute = flockRoute.route, let unwrappedFlockFromPin = flockRoute.from.pin, let unwrappedFlockToPin = flockRoute.to.pin else {
                continue
            }
            
            // TODO - remove
//            print("routeDistance:\(unwrappedFlockRoute.distance)")
//            for step in unwrappedFlockRoute.steps {
//                print("step:\(step.instructions)")
//            }
            
            view.addOverlay(unwrappedFlockRoute.polyline)
            view.addAnnotation(MKPointAnnotation(__coordinate: unwrappedFlockFromPin.placemark.coordinate, title: flockRoute.from.annotationType, subtitle: ""))
            view.addAnnotation(MKPointAnnotation(__coordinate: unwrappedFlockToPin.placemark.coordinate, title: flockRoute.to.annotationType, subtitle: ""))
            
            // for each route, find the one with the largest boundingRect and use as whole view rect
            let boundingRect = unwrappedFlockRoute.polyline.boundingMapRect
            if boundingRect.origin.x < minX {
                minX = boundingRect.origin.x
            }
            if boundingRect.origin.y < minY {
                minY = boundingRect.origin.y
            }
            if boundingRect.width > width {
                width = boundingRect.width
            }
            if boundingRect.height > height {
                height = boundingRect.height
            }
        }
        let rect: MKMapRect = MKMapRect(origin: MKMapPoint(x: minX, y: minY),size: MKMapSize(width: width, height: height))
        view.setVisibleMapRect(rect, edgePadding: UIEdgeInsets.init(top: 90.0, left: 75.0, bottom: 75.0, right: 75.0), animated: true)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        updateUIView(mapView, context: context)
        return mapView
    }
    
}




#Preview {
    HomeView()
}
