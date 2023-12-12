
import Foundation
import MapKit

struct DefaultMapKitLocation {
    public static var locationString: String = "Columbus, OH United States"
    public static var pin: MKMapItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 39.923000, longitude: -82.995030)))
    public static var region: MKCoordinateRegion =
        MKCoordinateRegion(
            center: pin.placemark.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.17,
                longitudeDelta: 0.17
            )
        )
    public static var rect: MKMapRect = MKMapRect(origin: MKMapPoint(pin.placemark.coordinate), size: MKMapSize(width: 100, height: 100))
}
