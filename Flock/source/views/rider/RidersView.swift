
import Foundation
import SwiftUI

struct RidersView: View {
    @Binding var trip: Trip
    @State var isKeyboardVisible: Bool = false
    @State var newRiderName: String = ""
    @State var newRiderPhone: String = ""
    @State var riderLocationSheetPresent: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                RiderList
                AddRiderButton
            }
        }
    }
    
    var RiderList: some View {
        List {
            ForEach($trip.riders) { $rider in
                NavigationLink(destination: {
                    RiderDetailsView(rider: $rider, isUseSuggestedDrivers: $trip.useSuggestedDrivers, isMeProfile: false)
                }) {
                    HStack {
                        VStack {
                            HStack {
                                Text(rider.name).bold()
                                Spacer()
                                Text(rider.phoneNumber)
                                Spacer()
                            }
                            HStack {
                                Text(rider.location).font(.subheadline).foregroundStyle(.gray).lineLimit(1)
                                Spacer()
                            }
                        }
                        Image(systemName: rider.isDriver ? "steeringwheel" : "figure.seated.seatbelt")
                            .fontWeight(.thin)
                            .onTapGesture {
                                if !trip.useSuggestedDrivers {
                                    rider.isDriver.toggle()
                                }
                            }
                    }
                    .padding(.vertical, 10)
                }
            }
            .onDelete(perform: { indexSet in
                trip.riders.remove(atOffsets: indexSet)
            })
        }
        .listStyle(.plain)
    }
    
    var AddRiderButton: some View {
        AddButton("Add Rider", destination: AnyView(AddRiderView(trip: $trip)))
    }
}

#Preview {
    HomeView()
}
