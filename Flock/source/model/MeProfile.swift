
import Foundation

struct MeProfile: Encodable, Decodable, Hashable, Identifiable {
    var id = UUID()
    var content: Rider
}
