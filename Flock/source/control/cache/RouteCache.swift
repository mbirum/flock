
import Foundation
import MapKit

class RouteCache: ObservableObject {
    
    public static var shared: RouteCache = RouteCache()
    
    @Published var lookup:[RouteCacheKey: RouteCacheItem] = [:]
    
    static func get(_ key: RouteCacheKey) -> RouteCacheItem? {
        return shared.lookup[key]
    }
    
    static func put(key: RouteCacheKey, route: MKRoute) -> Void {
        shared.lookup[key] = RouteCacheItem(route: route)
    }

    static func isRouteCached(source: String, destination: String) -> Bool {
        let key: RouteCacheKey = RouteCacheKey(source: source, destination: destination)
        guard let _ = shared.lookup[key] else { return false }
        return true
    }
    
}

struct RouteCacheKey: Hashable {
    var source: String
    var destination: String
    
    static func == (lhs: RouteCacheKey, rhs: RouteCacheKey) -> Bool {
        return lhs.source == rhs.source && lhs.destination == rhs.destination
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(source)
        hasher.combine(destination)
    }
}

struct RouteCacheItem {
    var route: MKRoute
}
