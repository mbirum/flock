
import Foundation
import SwiftUI
import MapKit
import mbutils

struct TripOverviewView: View, KeyboardReadable {
    @State var isSuggestedDriverTooltipPresent: Bool = false
    @State var isKeyboardVisible: Bool = false
    @State var isSearchPresent: Bool = true
    @State var isLocationSearchSheetPresent: Bool = false
    @State var isTitlePopoverPresent: Bool = false
    @State var isMapViewPresent: Bool = false
    @Binding var trip: Trip
    @State var optimizedTrip: OptimizedTrip? = nil
    @State var loadOverlayPresent: Bool = false
    @State var invalidateView: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                CustomNavTitle(title: $trip.name, divide: false, isEditable: true, onTap: {
                    isTitlePopoverPresent.toggle()
                })
                SubHeader
                DetailsForm
                MapModule
                    .onAppear(perform: {
                        if TripOptimizer.isFree() {
                            TripOptimizer.optimize(trip)
                            startOptimizedTripChecker()
                        }
                    })
                    .onChange(of: trip) { oldValue, newValue in
                        if TripOptimizer.isFree() {
                            TripOptimizer.optimize(newValue)
                            startOptimizedTripChecker()
                        }
                    }
            
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
    
    // Since route calculation requests are async, start an interval timer that
    // checks to see if requests are finished. Invalidate inner view when complete
    func startOptimizedTripChecker() -> Void {
        loadOverlayPresent = true
        TimerBasedConditionCheck.create(condition: {
            return TripOptimizer.isRequestComplete()
        }, complete: {
            guard let optimizedTrip = TripOptimizer.getOptimizedTrip() else { return }
            self.optimizedTrip = optimizedTrip
            if trip.useSuggestedDrivers {
                setNewSuggestedDriver()
            }
            OptimizedTripCache.put(trip: trip, optimizedTrip: optimizedTrip)
            TripOptimizer.queue.clear()
            invalidateView.toggle()
            loadOverlayPresent = false
        })
    }
    
    func setNewSuggestedDriver() -> Void {
        guard let uOptimizedTrip = optimizedTrip else { return }
        var suggestedDriverIds: [UUID] = []
        for variation in uOptimizedTrip.tripVariations {
            guard let driver = variation.driver else { continue }
            suggestedDriverIds.append(driver.riderId)
        }
        if suggestedDriverIds.isEmpty {
            return
        }
        for rider in $trip.riders {
            if suggestedDriverIds.contains(rider.id) {
                rider.wrappedValue.isDriver = true
            }
            else {
                rider.wrappedValue.isDriver = false
            }
        }
        uOptimizedTrip.setDrivers()
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
                .padding(.vertical, 6)
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
                    .padding(.vertical, 6)
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
                            Text("Drivers & Passengers")
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
                        .padding(.vertical, 5)
                    }
                    NavigationLink(destination: {
                        TripDetailsView(
                            trip: trip,
                            optimizedTrip: optimizedTrip,
                            invalidateView: $invalidateView
                        
                        )
                    }) {
                        HStack {
                            Image(systemName: "list.dash")
                            Text("Step by Step")
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
        }
    }
    
    var MapModule: some View {
        ZStack {
//            TripMapView(trip: $trip, optimizedTrip: $optimizedTrip)
            ZStack {
                TripMapViewRepresentable(
                    invalidateView: $invalidateView,
                    optimizedTrip: $optimizedTrip
                )
                if loadOverlayPresent {
                    ProgressView()
                }
            }
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
//            TripMapView(trip: $trip, optimizedTrip: $optimizedTrip)
            ZStack {
                TripMapViewRepresentable(
                    invalidateView: $invalidateView,
                    optimizedTrip: $optimizedTrip
                )
                if loadOverlayPresent {
                    ProgressView()
                }
            }
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




// inner MapKit 'representable' view
struct TripMapViewRepresentable: UIViewRepresentable {
    
    @Binding var invalidateView: Bool
    @Binding var optimizedTrip: OptimizedTrip?
    
    var mapViewDelegate: MapViewDelegate = MapViewDelegate()
    
    func getRegion() -> MKCoordinateRegion {
        return DefaultMapKitLocation.region
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        for annotation in view.annotations {
            view.removeAnnotation(annotation)
        }
        for overlay in view.overlays {
            view.removeOverlay(overlay)
        }
        view.delegate = mapViewDelegate
        view.setRegion(getRegion(), animated: true)
        view.setVisibleMapRect(
            DefaultMapKitLocation.rect,
            edgePadding: UIEdgeInsets.init(top: 100.0, left: 50.0, bottom: 100.0, right: 50.0),
            animated: true
        )
        
        guard let uOptimizedTrip = optimizedTrip else { return }
        
        var minX: Double = Double.greatestFiniteMagnitude
        var minY: Double = Double.greatestFiniteMagnitude
        var width: Double = 0
        var height: Double = 0
        for tripVariation in uOptimizedTrip.tripVariations {
            for flockRoute in tripVariation.routes {
                guard let uFlockRoute = flockRoute.route,
                        let uFlockFromPin = flockRoute.from.pin,
                        let uFlockToPin = flockRoute.to.pin
                else {
                    continue
                }

                view.addOverlay(uFlockRoute.polyline)
                view.addAnnotation(MKPointAnnotation(__coordinate: uFlockFromPin.placemark.coordinate, title: flockRoute.from.annotationType, subtitle: ""))
                view.addAnnotation(MKPointAnnotation(__coordinate: uFlockToPin.placemark.coordinate, title: flockRoute.to.annotationType, subtitle: ""))
                
                // for each route, find the one with the largest boundingRect and use as whole view rect
                let rect = uFlockRoute.polyline.boundingMapRect
                if rect.origin.x < minX { minX = rect.origin.x }
                if rect.origin.y < minY { minY = rect.origin.y }
                if rect.width > width { width = rect.width }
                if rect.height > height { height = rect.height }
            }
        }
        let rect: MKMapRect = MKMapRect(
            origin: MKMapPoint(x: minX, y: minY),
            size: MKMapSize(width: width, height: height)
        )
        view.setVisibleMapRect(rect, edgePadding: UIEdgeInsets.init(top: 90.0, left: 75.0, bottom: 75.0, right: 75.0), animated: true)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        updateUIView(mapView, context: context)
        return mapView
    }
    
}

#Preview {
    HomeView()
}
