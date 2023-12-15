
import Foundation
import MapKit

class MapViewDelegate: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(named: "ButtonColor")
        renderer.lineWidth = 5.0
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "custom")
        
        if annotationView == nil {
            //Create View
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "custom")
        } else {
            //Assign annotation
            annotationView?.annotation = annotation
        }
        
        //Set image
        switch annotation.title {
        case "source":
            annotationView?.image = UIImage(systemName: "car.rear.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
        case "destination":
            annotationView?.image = UIImage(systemName: "flag.checkered")
        default:
            annotationView?.image = UIImage(named: "AppIcon")
            annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            break
        }
        
        return annotationView
    }
}
