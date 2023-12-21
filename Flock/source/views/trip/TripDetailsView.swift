
import Foundation
import SwiftUI
import MapKit
import mbutils

struct TripDetailsView: View, KeyboardReadable {
    @State var isSuggestedDriverTooltipPresent: Bool = false
    @State var isKeyboardVisible: Bool = false
    @State var isSearchPresent: Bool = true
    @State var isLocationSearchSheetPresent: Bool = false
    @State var isTitlePopoverPresent: Bool = false
    @State var isMapViewPresent: Bool = false
    @Binding var trip: Trip
    
    var body: some View {
        NavigationStack {
            VStack {
                CustomNavTitle(title: $trip.name, divide: false, isEditable: true, onTap: {
                    isTitlePopoverPresent.toggle()
                })
                SubHeader
                DetailsForm
                MapModule
            
            }
            .onAppear(perform: {
                if trip.useSuggestedDrivers {
                    if trip.drivers == 0 {
                        for rider in $trip.riders {
                            rider.wrappedValue.isDriver = true
                            break
                        }
                    }
                }
            })
            .sheet(isPresented: $isTitlePopoverPresent) {
                GenericTextFieldSheet(label: "Name", field: $trip.name, isPresent: $isTitlePopoverPresent)
            }
            
            .sheet(isPresented: $isLocationSearchSheetPresent) {
                LocationSheet
            }
            
            .popover(isPresented: $isMapViewPresent) {
                LargeMapModule
            }
            
        }
        .ignoresSafeArea(.keyboard)
    }
    
    var SubHeader: some View {
        HStack {
            Text(trip.destination)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 15)
                .lineLimit(3)
            Spacer()
        }
    }
    
    var DetailsForm: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: "location.fill").foregroundStyle(Color("AccentColor"))
                    Text(trip.destination).font(.subheadline).foregroundStyle(.gray).lineLimit(1).baselineOffset(-2.0)
                    Spacer()
                }
                .cornerRadius(8)
                .contentShape(Rectangle())
                .padding(.vertical, 9)
                .onTapGesture {
                    isLocationSearchSheetPresent.toggle()
                }
                Toggle(isOn: $trip.useSuggestedDrivers, label: {
                    HStack {
                        Text("Use suggested drivers")
                        Image(systemName: "questionmark.circle")
                            .onTapGesture {
                                isSuggestedDriverTooltipPresent.toggle()
                            }.foregroundStyle(.gray)
                    }
                    .padding(.vertical, 9)
                })
                .alert(
                    "Suggested drivers",
                    isPresented: $isSuggestedDriverTooltipPresent,
                    presenting: String("Drivers have been chosen for optimal efficiency. Turn this feature off if you want to choose your own")
                ) { msg in
                    
                } message: { msg in
                    Text(msg)
                }
            
        
                List {
                    NavigationLink(destination: {
                        RidersView(trip: $trip)
                    }) {
                        HStack {
                            Text("Drivers & Passengers").bold()
                            Spacer()
                            Image(systemName: "steeringwheel")
                                .padding(.horizontal, -6)
                                .padding(.leading, 8)
                            Text(String(trip.drivers))
                                .font(.system(size: 16.0))
                                .baselineOffset(-6.0)
                                .padding(.trailing, 10)
                        
                            Image(systemName: "figure.seated.seatbelt")
                                .padding(.horizontal, -6)
                            Text(String(trip.passengers))
                                .font(.system(size: 16.0))
                                .baselineOffset(-6.0)
                                .padding(.trailing, 5)
                        }
                        .padding(.vertical, 7)
                    }
                }
            }
        }
    }
    
    var MapModule: some View {
        ZStack {
            TripMapView(trip: $trip)
            HStack {
                Image(systemName: "plus.magnifyingglass")
                    .padding(.all, 10)
                    .contentShape(Rectangle())
                    .background(.white)
            }
            .cornerRadius(5)
            .position(x:25,y:25)
            .onTapGesture {
                isMapViewPresent.toggle()
            }
        }
    }
    
    var LargeMapModule: some View {
        VStack {
            HStack {
                Button("Done", action: {
                    isMapViewPresent.toggle()
                })
                Spacer()
            }
            .padding(18)
            .padding(.top, 5)
            .padding(.trailing, 5)
            TripMapView(trip: $trip)
        }
    }
    
    var LocationSheet: some View {
        LocationSearchView(
            onResultTap: { completion in
                isLocationSearchSheetPresent.toggle()
                trip.destination = "\(completion.title) \(completion.subtitle)"
            },
            isPresent: $isLocationSearchSheetPresent
        )
    }
}

#Preview {
    HomeView()
}
