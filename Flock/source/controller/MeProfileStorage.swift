
import Foundation
import mbutils

class MeProfileStorage: AppDataStorage<MeProfile> {
    
    public static var shared: MeProfileStorage = MeProfileStorage()
    
    public var profile: MeProfile {
        get {
            if data.count <= 0 {
                data.append(MeProfile(content: Rider(name: "", phoneNumber: "", isDriver: true)))
            }
            return data[0]
        }
        set { self.data[0] = newValue }
    }
    
}
