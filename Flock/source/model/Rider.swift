
import Foundation
import MapKit

struct Rider: Encodable, Decodable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var phoneNumber: String
    var location: String = "Unknown location"
    var isDriver: Bool = false
    var passengerCapacity: Int = 4
}
