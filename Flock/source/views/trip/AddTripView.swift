
import Foundation
import SwiftUI

struct AddTripView: View {
    @State var tripData: TripDataStorage = TripDataStorage.shared
    @State var newTrip: Trip = Trip(name:"New Trip", destination: "Unknown destination", useSuggestedDrivers: true, riders: [
//        Rider(name: "Matt Birum", phoneNumber: "567-204-1135"),
//        Rider(name: "Erin Birum", phoneNumber: "614-580-8174")
        MeProfileStorage.shared.profile.content
    ])
    
    var body: some View {
        VStack {
            ForEach($tripData.trips) { $trip in
                if (trip.id == newTrip.id) {
                    TripOverviewView(trip: $trip)
                }
            }
        }
        .onAppear(perform: {
            tripData.addOrUpdateTrip(newTrip)
        })
    }
}
