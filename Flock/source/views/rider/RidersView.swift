
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
                AddButton
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
                        Image(systemName: "steeringwheel")
                            .fontWeight(.thin)
                            .opacity((rider.isDriver) ? 1.0 : 0.3)
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
    
    var AddButton: some View {
        VStack {
            HStack {
                NavigationLink(destination: {
                    AddRiderView(trip: $trip)
                }) {
                    HStack {
                        Spacer()
                        Text("Add Rider")
                        Spacer()
                    }
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color("AccentColor"))
            .foregroundStyle(.white)
            .cornerRadius(8)
        }
        .frame(height: 75)
        .padding(.horizontal, 25)
    }
}

