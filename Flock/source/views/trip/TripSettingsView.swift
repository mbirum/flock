
import SwiftUI

struct TripSettingsView: View {
    
    @Binding var trip: Trip
    @State var isLocationSearchSheetPresent: Bool = false
    @State var isTitlePopoverPresent: Bool = false
    @State var isSuggestedDriverTooltipPresent: Bool = false
    
    var body: some View {
        VStack {
            SettingsForm
            Sheets
        }
    }
    
    var NavTitle: some View {
        VStack {
            HStack {
                Text("Settings")
                    .padding(.leading, 15)
                    .padding(.top, 10)
                    .font(.system(size: 28))
                    .bold()
                Image(systemName: "gear")
                    .fontWeight(.thin)
                    .font(.system(size: 24))
                    .padding(.bottom, -12)
                Spacer()
            }
        }
    }
    
    var SettingsForm: some View {
        Form {
            HStack {
                Image(systemName: "pencil.line")
                    .fontWeight(.thin)
                Text(trip.name).font(.subheadline).lineLimit(1)
            }
            .onTapGesture {
                isTitlePopoverPresent.toggle()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 10)
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color("AccentColor"))
                    .fontWeight(.thin)
                Text(trip.destination).font(.subheadline).lineLimit(1)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 9)
            .onTapGesture {
                isLocationSearchSheetPresent.toggle()
            }
            
            HStack {
                Image(systemName: "steeringwheel")
                    .fontWeight(.thin)
                Toggle(isOn: $trip.useSuggestedDrivers, label: {
                    HStack {
                        Text("Use suggested drivers")
                            .padding(.leading, 0)
                        Spacer()
                    }
                    
                })
                .toggleStyle(.button)
                .padding(.vertical, 5)
                .alert(
                    "Suggested drivers",
                    isPresented: $isSuggestedDriverTooltipPresent,
                    presenting: String("Drivers have been chosen for optimal efficiency. Turn this feature off if you want to choose your own")
                ) { msg in
                    
                } message: { msg in
                    Text(msg)
                }
                Image(systemName: "questionmark.circle")
                    .fontWeight(.thin)
                    .onTapGesture {
                        isSuggestedDriverTooltipPresent.toggle()
                    }.foregroundStyle(.gray)
            }
        }
    }
    
    var Sheets: some View {
        HStack {}
        .sheet(isPresented: $isTitlePopoverPresent) {
            GenericTextFieldSheet(
                label: "Name",
                field: $trip.name,
                isPresent: $isTitlePopoverPresent
            )
        }
        .sheet(isPresented: $isLocationSearchSheetPresent) {
            LocationSheet
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
