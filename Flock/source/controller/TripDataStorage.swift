
import Foundation
import SwiftUI
import mbutils

class TripDataStorage: AppDataStorage<Trip> {
    
    public static var shared: TripDataStorage = TripDataStorage()
    
    public var trips: [Trip] {
        get { return data }
        set { self.data = newValue }
    }
    
    public func setTrips(trips: [Trip]) -> Void {
        self.trips = trips
    }
    
    func addOrUpdateTrip(_ trip: Trip) -> Void {
        for var existingTrip in self.trips {
            if (existingTrip.id == trip.id) {
                existingTrip.from(trip)
                return
            }
        }
        self.trips.append(trip)
    }
    
    public func removeTrips(indexSet: IndexSet) -> Void {
        self.trips.remove(atOffsets: indexSet)
    }
    
}
