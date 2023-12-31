
import SwiftUI
import MapKit

struct SinglePinMapView: View {
    
    @State var riderId: UUID?
    @Binding var pinLocationString: String
    @State var pin: MKMapItem = UserLocationManager.getUserPin()
    
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
        if !RiderLocationCache.hasLocationChanged(id: self.riderId, locationString: self.pinLocationString) {
            guard let uRiderId = riderId else { return }
            guard let uCacheItem = RiderLocationCache.get(uRiderId) else { return }
            self.pin = uCacheItem.pin
        }
        else {
            LocationSearchService.translateLocationToMapItem(
                location: self.pinLocationString,
                mapItemHandler: { item in
                    self.pin = item
                    guard let uRiderId = self.riderId else { return }
                    RiderLocationCache.put(id: uRiderId, locationString: self.pinLocationString, pin: item)
                }
            )
        }
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
