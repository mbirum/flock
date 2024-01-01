
import Foundation
import SwiftUI
import MapKit

struct RiderDetailsView: View {
    @Binding var rider: Rider
    @Binding var isUseSuggestedDrivers: Bool
    @State var isMeProfile: Bool
    @State var isKeyboardVisible: Bool = false
    @State var newLocation: String = ""
    @State var isLocationSearchSheetPresent: Bool = false
    @State var isTitlePopoverPresent: Bool = false
    @State var isMapViewPresent: Bool = false
    
    @State var formName: String = ""
    @State var formPhone: String = ""
    @State var formCapacity: Int = 3
    
    var body: some View {
        NavigationStack {
            VStack {
                RiderDetails
                MapModule
            }
            .sheet(isPresented: $isTitlePopoverPresent) {
                GenericTextFieldSheet(label: "Name", field: $formName, isPresent: $isTitlePopoverPresent)
                    .onDisappear(perform: {
                        rider.name = self.formName
                    })
            }
            
            .popover(isPresented: $isMapViewPresent) {
                LargeMapModule
            }
            
        }
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: {
            self.formName = rider.name
            self.formPhone = rider.phoneNumber
            self.formCapacity = rider.passengerCapacity
        })
        .sheet(isPresented: $isLocationSearchSheetPresent) {
            LocationSheet
        }
        .navigationBarItems(trailing: Image(systemName: (isMeProfile) ? "person.circle" : (rider.isDriver) ? "steeringwheel" : "figure.seated.seatbelt").fontWeight(.thin))

    }
    
    var RiderDetails: some View {
        VStack {
            CustomNavTitle {
                DefaultNavTitleText(rider.name)
            }
            .editable {
                isTitlePopoverPresent.toggle()
            }
            .padding(.bottom, 2)

            if !isMeProfile {
                SubHeader
            }
            
            Divider()
            
            HStack {
                Image(systemName: "phone.fill").fontWeight(.thin)
                PhoneNumberTextField(value: $formPhone)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .onChange(of: formPhone) { oldValue, newValue in
                rider.phoneNumber = formPhone
            }
            
            Divider()
            
            HStack {
                Image(systemName: "location.fill")
                    .foregroundStyle(Color("AccentColor"))
                    .fontWeight(.thin)
                Text(rider.location).font(.subheadline).foregroundStyle(.gray).lineLimit(1).baselineOffset(-2.0)
                Spacer()
            }
            .cornerRadius(8)
            .contentShape(Rectangle())
            .padding(.vertical, 9)
            .padding(.horizontal, 15)
            .onTapGesture {
                isLocationSearchSheetPresent.toggle()
            }
            
            if !isMeProfile {
                Divider()
                IsDrivingToggle
            }
            Divider()
            CapacityStack
            Divider()
        }
//        .padding(.bottom, 5)
    }
    
    var SubHeader: some View {
        HStack {
            Text("\(Text(rider.isDriver ? "Driving from" : "Getting picked up @").bold()) \(rider.location)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 15)
                .padding(.bottom, 2)
                .lineLimit(3)
            Spacer()
        }
    }
    
    var DetailsForm: some View {
        Text("hello")
    }
    
    var LocationSheet: some View {
        LocationSearchView(
            onResultTap: { completion in
                isLocationSearchSheetPresent.toggle()
                rider.location = "\(completion.title) \(completion.subtitle)"
            },
            isPresent: $isLocationSearchSheetPresent
        )
    }
    
    var MapModule: some View {
        ZStack {
            SinglePinMapView(riderId: rider.id, pinLocationString: $rider.location)
            EnlargeMapButton
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
            SinglePinMapView(riderId: rider.id, pinLocationString: $rider.location)
        }
    }
    
    var IsDrivingToggle: some View {
        HStack {
            Image(systemName: "steeringwheel")
                .fontWeight(.thin)
            Toggle("Driving", isOn: $rider.isDriver)
                .disabled(isUseSuggestedDrivers)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 15)
    }
    
    var CapacityStack: some View {
        HStack {
            Image(systemName: "car")
                .fontWeight(.thin)
            Text("Capacity")
            Picker("Capacity", selection: $formCapacity) {
                ForEach(1...8, id: \.self) {
                    Text(String($0)).tag($0)
                }
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .pickerStyle(.segmented)
            .onChange(of: formCapacity) { oldValue, newValue in
                rider.passengerCapacity = newValue
            }
        }
        .padding(.horizontal, 15)
    }
    
    var EnlargeMapButton: some View {
        let shadowRadius: CGFloat = 10
        return VStack {
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "plus.magnifyingglass")
                    .fontWeight(.thin)
                    .padding(.all, 15)
                    .contentShape(Rectangle())
                    .background(.white)
                    .cornerRadius(50)
                    .shadow(radius: shadowRadius)
            }
            .padding(.bottom, 10)
            .padding(.trailing, 10)
            .onTapGesture {
                isMapViewPresent.toggle()
            }
        }
    }
}

#Preview {
    HomeView()
}
