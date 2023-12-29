
import Foundation
import SwiftUI
import MapKit
import mbutils

struct TripView: View, KeyboardReadable {
    
    @Binding var trip: Trip
    
    @State var isMapViewPresent: Bool = false
    @State var optimizedTrip: OptimizedTrip? = nil
    @State var loadOverlayPresent: Bool = false
    @State var invalidateView: Bool = false
    @State var isTripSettingsPresent: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                NavTitle
                SubHeader
                MapModule
            }
            OnAppear
            Sheets
        }
        .sheet(isPresented: $isTripSettingsPresent) {
            TripSettingsView(trip: $trip)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            
        }
    }
    
    func checkAndOptimizeTrip(trip: Trip) -> Void {
        if trip.destination != "Unknown destination" {
            if TripOptimizer.isFree() {
                TripOptimizer.optimize(trip)
                startOptimizedTripChecker()
            }
        }
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
    
    var NavTitle: some View {
        VStack {
            HStack {
                Text(trip.name)
                    .padding(.leading, 15)
                    .padding(.top, 10)
                    .font(.system(size: 28))
                    .bold()
                    .lineLimit(1)
                Spacer()
//                NavigationLink(destination: {
//                    TripSettingsView(trip: $trip)
//                }) {
//                    Image(systemName: "gear")
//                        .fontWeight(.thin)
//                        .font(.system(size: 26))
//                        .padding(.trailing, 15)
//                        .padding(.bottom, -10)
//                }
//                .foregroundStyle(.black)
            }
        }
        .padding(.bottom, -2)
    }
    
    var SubHeader: some View {
        VStack {
            HStack {
                Text(trip.destination)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .padding(.bottom, 5)
        }
    }
    
    var MapModule: some View {
        ZStack {
            ZStack {
                TripMapViewRepresentable(
                    invalidateView: $invalidateView,
                    optimizedTrip: $optimizedTrip
                )
                if loadOverlayPresent {
                    ProgressView()
                }
            }
            MapButtonCollection
            EnlargeMapButton
        }
        .onAppear(perform: {
            checkAndOptimizeTrip(trip: trip)
        })
        .onChange(of: trip) { oldValue, newValue in
            checkAndOptimizeTrip(trip: newValue)
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
    
    var MapButtonCollection: some View {
        let shadowRadius: CGFloat = 10
        let cornerRadius: CGFloat = 25
        let chevronSize: CGFloat = 12
        let riderNumFontSize: CGFloat = 16
        let riderNumOffset: CGFloat = -6.0
        let riderIconTrailingPadding: CGFloat = -6
        return VStack {
            HStack {
                HStack {
                    HStack {
                        Image(systemName: "gear")
                            .fontWeight(.thin)
                            .font(.system(size: 26))
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    .padding(.bottom, 7)
                    .contentShape(Rectangle())
                    .background(.white)
                    .cornerRadius(cornerRadius)
                    .shadow(radius: shadowRadius)
                    .onTapGesture {
                        isTripSettingsPresent.toggle()
                    }
                }
                
                Spacer()
                
                HStack {
                    NavigationLink(destination: {
                        TripStepsView(
                            trip: trip,
                            optimizedTrip: optimizedTrip,
                            invalidateView: $invalidateView
                        )
                    }) {
                        HStack {
                            Image(systemName: "text.append")
                                .fontWeight(.thin)
                            Text("Steps")
                            Image(systemName: "chevron.right")
                                .fontWeight(.thin)
                                .font(.system(size: chevronSize))
                                .foregroundStyle(.gray)
                        }
                        .padding(.all, 10)
                        .contentShape(Rectangle())
                        .background(.white)
                        .cornerRadius(cornerRadius)
                        .shadow(radius: shadowRadius)
                        
                    }
                    .foregroundStyle(.black)
                }
                
                Spacer()
                
                HStack {
                    NavigationLink(destination: {
                        RidersView(trip: $trip)
                    }) {
                        HStack {
                            Image(systemName: "steeringwheel")
                                .fontWeight(.thin)
                                .padding(.trailing, riderIconTrailingPadding)
                            Text(String(trip.drivers))
                                .font(.system(size: riderNumFontSize))
                                .baselineOffset(riderNumOffset)
                            
                            Image(systemName: "figure.seated.seatbelt")
                                .fontWeight(.thin)
                                .padding(.leading, 2)
                                .padding(.trailing, riderIconTrailingPadding)
                            Text(String(trip.passengers))
                                .font(.system(size: riderNumFontSize))
                                .baselineOffset(riderNumOffset)
                                .padding(.trailing, 5)
                            Text("Riders")
                            Image(systemName: "chevron.right")
                                .fontWeight(.thin)
                                .font(.system(size: chevronSize))
                                .foregroundStyle(.gray)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 8)
                        .padding(.bottom, 7)
                        .contentShape(Rectangle())
                        .background(.white)
                        .cornerRadius(cornerRadius)
                        .shadow(radius: shadowRadius)
                        
                    }
                    .foregroundStyle(.black)
                }
                
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
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
    
    var OnAppear: some View {
        HStack {}
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
    }

    var Sheets: some View {
        HStack {}
        .popover(isPresented: $isMapViewPresent) {
            LargeMapModule
        }
        
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
