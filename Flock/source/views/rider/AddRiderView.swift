
import Foundation
import SwiftUI

struct AddRiderView: View {
    @Binding var trip: Trip
    @State var newRider: Rider = Rider(name: "New Passenger", phoneNumber: "")
    
    var body: some View {
        VStack {
            ForEach($trip.riders) { $rider in
                if (rider.id == newRider.id) {
                    RiderDetailsView(rider: $rider, isUseSuggestedDrivers: $trip.useSuggestedDrivers, isMeProfile: false)
                }
            }
        }
        .onAppear(perform: {
            trip.riders.append(newRider)
        })
    }
}
