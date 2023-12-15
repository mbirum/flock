
import Foundation
import SwiftUI
import MapKit

struct RiderDetailsView: View, KeyboardReadable {
    @State var meProfileTitle: String = "Me"
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
                CustomNavTitle(title: $rider.name, divide: false, isEditable: true, onTap: {
                    isTitlePopoverPresent.toggle()
                })
                if !isMeProfile {
                    SubHeader
                }
                DetailsForm
                MapModule
                    .frame(height:200)
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
        .navigationBarItems(trailing: Image(systemName: (isMeProfile) ? "person.circle" : (rider.isDriver) ? "steeringwheel" : "figure.seated.seatbelt"))

    }
    
    var SubHeader: some View {
        HStack {
            Text("\(Text(rider.isDriver ? "Driving from" : "Getting picked up @").bold()) \(rider.location)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 15)
                .lineLimit(3)
            Spacer()
        }
    }
    
    var DetailsForm: some View {
        Form {
            HStack {
                Image(systemName: "phone.fill")
                PhoneNumberTextField(value: $formPhone)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 8)
            .onChange(of: formPhone) { oldValue, newValue in
                rider.phoneNumber = formPhone
            }
            HStack {
                Image(systemName: "location.fill").foregroundStyle(Color("ButtonColor"))
                Text(rider.location).font(.subheadline).foregroundStyle(.gray).lineLimit(1).baselineOffset(-2.0)
                Spacer()
            }
            .cornerRadius(8)
            .contentShape(Rectangle())
            .padding(.vertical, 9)
            .onTapGesture {
                isLocationSearchSheetPresent.toggle()
            }
            
            if isMeProfile {
                CapacityStack
            }
            else {
                IsDrivingToggle
                if rider.isDriver {
                    CapacityStack
                }
            }
        }
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
            SinglePinMapView(riderId: rider.id, pinLocationString: $rider.location)
        }
    }
    
    var IsDrivingToggle: some View {
        Toggle("Driving", isOn: $rider.isDriver).disabled(isUseSuggestedDrivers).padding(.vertical, 4)
    }
    
    var CapacityStack : some View {
        HStack {
            Text("Capacity")
            Picker("Capacity", selection: $formCapacity) {
                ForEach(1...7, id: \.self) {
                    Text(String($0)).tag($0)
                }
            }
            .padding(.vertical, 4)
            .pickerStyle(.segmented)
            .onChange(of: formCapacity) { oldValue, newValue in
                rider.passengerCapacity = newValue
            }
        }
    }
}
