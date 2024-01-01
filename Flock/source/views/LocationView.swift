
import Foundation
import SwiftUI
import MapKit

struct LocationView: View {
    
    @StateObject var location = ObservableLocation()
    
    var body: some View {
        VStack {
            LocationMapViewRepresentable(locationPin: $location.userPin)
        }
    }
}

class ObservableLocation: NSObject, ObservableObject {
    @objc var userLocationManager = UserLocationManager.shared
    var pinObservation: NSKeyValueObservation?
    
    @Published var userPin: MKMapItem = UserLocationManager.getUserPin()
    
    override init() {
        super.init()
        initializeObservations()
    }
    
    func initializeObservations() -> Void {
        pinObservation = observe(\.userLocationManager.pin, options: [.old, .new]) { object, change in
            guard let uPin = self.userLocationManager.pin else { return }
            self.userPin = uPin
        }
    }
}

struct LocationMapViewRepresentable: UIViewRepresentable {
    
//    @Binding var invalidateView: Bool
    @Binding var locationPin: MKMapItem
    
    var mapViewDelegate: MapViewDelegate = MapViewDelegate()
    
    func updateUIView(_ view: MKMapView, context: Context) {
        for annotation in view.annotations {
            view.removeAnnotation(annotation)
        }
        for overlay in view.overlays {
            view.removeOverlay(overlay)
        }
        view.delegate = mapViewDelegate
        
        view.addAnnotation(MKPointAnnotation(__coordinate: locationPin.placemark.coordinate))
        view.setRegion(MKCoordinateRegion(
            center: locationPin.placemark.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.030,
                longitudeDelta: 0.030
            )
        ), animated: true)
//            let rect: MKMapRect = MKMapRect(
//                origin: MKMapPoint(x: minX, y: minY),
//                size: MKMapSize(width: width, height: height)
//            )
//            view.setVisibleMapRect(rect, edgePadding: UIEdgeInsets.init(top: 90.0, left: 75.0, bottom: 75.0, right: 75.0), animated: true)
    
         
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        updateUIView(mapView, context: context)
        return mapView
    }
    
}

#Preview {
    LocationView()
}
