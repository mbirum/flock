
import Foundation
import SwiftUI

struct HomeView: View {
    @State var title: String = "Trips"
    @ObservedObject var tripData: TripDataStorage = TripDataStorage.shared
    @ObservedObject var meProfileStorage: MeProfileStorage = MeProfileStorage.shared
    
    var body: some View {
        TabView {
            NavigationStack {
                VStack {
                    CustomNavTitle(title: $title, divide: true, isEditable: false, onTap: {})
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
            MeProfileView(profile: $meProfileStorage.profile)
                .tabItem() {
                    Label("Me", systemImage: "person.circle")
                }
        }
    }
    
    var AddTripButton: some View {
        VStack {
            HStack {
                NavigationLink(destination: {
                    AddTripView()
                }) {
                    HStack {
                        Spacer()
                        Text("Add Trip")
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
    
    var TripList: some View {
        List {
            ForEach($tripData.trips) { $trip in
                NavigationLink(destination: {
                    TripDetailsView(trip: $trip)
                }) {
                    VStack {
                        HStack {
                            Text(trip.name).font(.headline).lineLimit(1)
                            Spacer()
                            HStack {
                                Image(systemName: "steeringwheel")
                                    .padding(.horizontal, -6)
                                    .padding(.leading, 8)
                                Text(String(trip.drivers))
                                    .font(.system(size: 11.0))
                                    .baselineOffset(-6.0)
                                    .padding(.trailing, -2)
                            
                                Image(systemName: "figure.seated.seatbelt")
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


