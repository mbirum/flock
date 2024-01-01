
import Foundation
import CoreLocation
import CoreLocationUI
import MapKit

struct DefaultCoordinate {
    static var latitude: CLLocationDegrees = 39.9421
    static var longitude: CLLocationDegrees = -82.9927
}

class UserLocationManager:NSObject, ObservableObject, CLLocationManagerDelegate {
    
    public static var DEFAULT_COORDINATE =
        CLLocationCoordinate2D(latitude: DefaultCoordinate.latitude, longitude: DefaultCoordinate.longitude)
    
    public static let shared = UserLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @objc dynamic var pin: MKMapItem?
    let manager = CLLocationManager()
    
    static func getUserPin() -> MKMapItem {
        guard let uPin = shared.pin else {
            return MKMapItem(
                placemark: MKPlacemark(coordinate: DEFAULT_COORDINATE)
            )
        }
        return uPin
    }
    
    static func getUserRegion() -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: getUserPin().placemark.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: 0.030,
                longitudeDelta: 0.030
            )
        )
    }
    
    static func getUserRect() -> MKMapRect {
        return MKMapRect(
            origin: MKMapPoint(getUserPin().placemark.coordinate),
            size: MKMapSize(width: 100, height: 100)
        )
    }
    
    override init() {
        super.init()
        manager.delegate = self
        request()
    }
    
    func isAuthorized() -> Bool {
        return manager.authorizationStatus == .authorizedAlways ||
            manager.authorizationStatus == .authorizedWhenInUse
    }
    
    func request() {
        guard isAuthorized() else {
            return manager.requestWhenInUseAuthorization()
        }
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
        if let uLocation = location {
            print("setting user location")
            pin = MKMapItem(placemark: MKPlacemark(coordinate: uLocation))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR:: \(error.localizedDescription)")
        print(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
            case .notDetermined:
                print("Location authorization not yet determined")
            case .restricted:
                print("Location restricted by parental control")
            case .denied:
                print("Location authorization denied")
            case .authorizedWhenInUse:
                print("Location authorized when in use")
                request()
            case .authorizedAlways:
                print("Location authorized always")
                request()
            default:
                print("No location auth case to cover")
        }
    }
}
