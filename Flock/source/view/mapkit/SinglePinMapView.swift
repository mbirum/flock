
import SwiftUI
import MapKit

struct SinglePinMapView: View {
    
    @Binding var pinLocationString: String
    @State var pin: MKMapItem = DefaultMapKitLocation.pin
    
    var body: some View {
        SinglePinMapViewRepresentable(pin: $pin)
        .onAppear(perform: {
            translateLocation(pinLocationString)
        })
        .onChange(of: pinLocationString) { oldValue, newValue in
            translateLocation(newValue)
        }
    }
    
    func translateLocation(_ location: String) -> Void {
        LocationSearchService.translateLocationToMapItem(
            location: location,
            mapItemHandler: { item in
                self.pin = item
            }
        )
    }
}

struct SinglePinMapViewRepresentable: UIViewRepresentable {
    
    @Binding var pin: MKMapItem
    
    var mapViewDelegate: MapViewDelegate = MapViewDelegate()
    
    func getRegion() -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: pin.placemark.coordinate,
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
        view.delegate = mapViewDelegate
        view.setRegion(getRegion(), animated: true)
        view.addAnnotation(MKPointAnnotation(__coordinate: pin.placemark.coordinate, title: "pin", subtitle: ""))
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        updateUIView(mapView, context: context)
        return mapView
    }
    
}
