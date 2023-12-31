
import Foundation
import SwiftUI

struct HomeView: View {
    @ObservedObject var tripData: TripDataStorage = TripDataStorage.shared
    @ObservedObject var meProfileStorage: MeProfileStorage = MeProfileStorage.shared
    
    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    NavTitle
                    TripList
                        .onAppear(perform: {
                            RiderLocationCache.initializeCache(from: tripData.trips)
                        })
                    AddTripButton
                }
            }
            .tabItem() {
                Label("Trips", systemImage: "car.rear.road.lane")
            }
            .padding(.bottom, 5)
            MeProfileView(profile: $meProfileStorage.profile)
                .tabItem() {
                    Label("Me", systemImage: "person.circle")
                }
                .padding(.bottom, 5)
            LocationView()
                .tabItem() {
                    Label("Location", systemImage: "location")
                }
                .padding(.bottom, 5)
        }
    }
    
    var NavTitle: some View {
        CustomNavTitle {
            DefaultNavTitleText("Trips")
        }
        .defaultPadding()
        .divider()
    }
    
    var AddTripButton: some View {
        AddButton("Add Trip", destination: AnyView(AddTripView()))
    }
    
    var TripList: some View {
        List {
            ForEach($tripData.trips) { $trip in
                NavigationLink(destination: {
                    TripView(trip: $trip)
                }) {
                    VStack {
                        HStack {
                            Text(trip.name).font(.headline).lineLimit(1)
                            Spacer()
                            HStack {
                                Image(systemName: "steeringwheel")
                                    .fontWeight(.thin)
                                    .padding(.horizontal, -6)
                                    .padding(.leading, 8)
                                Text(String(trip.drivers))
                                    .font(.system(size: 11.0))
                                    .baselineOffset(-6.0)
                                    .padding(.trailing, -2)
                            
                                Image(systemName: "figure.seated.seatbelt")
                                    .fontWeight(.thin)
                                    .padding(.trailing, -8)
                                Text(String(trip.passengers))
                                    .font(.system(size: 11.0))
                                    .baselineOffset(-6.0)
                                    .padding(.trailing, 15)
                            }
                            .padding(.top, 0.5)
                            .font(.system(size:13))
                            .opacity(0.85)
                        }
                        HStack {
                            Text(trip.destination).font(.subheadline).foregroundStyle(.gray).lineLimit(2)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .onDelete(perform: { indexSet in
                tripData.removeTrips(indexSet: indexSet)
            })
        }
        .listStyle(.plain)
    }
}

#Preview {
    HomeView()
}


