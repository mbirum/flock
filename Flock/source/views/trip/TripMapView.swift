
import SwiftUI
import MapKit
import mbutils

struct TripMapView: View {
    @Binding var trip: Trip
    @State var loadOverlayPresent: Bool = false
    @State var invalidateView: Bool = false
    @Binding var optimizedTrip: OptimizedTrip?
    
    var body: some View {
        ZStack {
            TripMapViewRepresentable(
                invalidateView: $invalidateView,
                optimizedTrip: $optimizedTrip
            )
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
            if loadOverlayPresent {
                ProgressView()
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
            if trip.useSuggestedDrivers {
                // TODO
                setNewSuggestedDriver()
            }
            self.optimizedTrip = optimizedTrip
            OptimizedTripCache.put(trip: trip, optimizedTrip: optimizedTrip)
            invalidateView.toggle()
            loadOverlayPresent = false
        })
    }
    
    func setNewSuggestedDriver() -> Void {
        // TODO
//        guard let uSuggestedDriverIds = optimizedTrip?.suggestedDriverIds else { return }
//        if uSuggestedDriverIds.count == 0 {
//            return
//        }
//        for rider in $trip.riders {
//            if uSuggestedDriverIds.contains(rider.id) {
//                rider.wrappedValue.isDriver = true
//            }
//            else {
//                rider.wrappedValue.isDriver = false
//            }
//        }
//        guard let uRouteStack = optimizedTrip?.routeStack else { return }
//        for route in uRouteStack {
//            if uSuggestedDriverIds.contains(route.from.riderId!) {
//                route.from.isDriver = true
//            }
//        }
    }
    
    
}




#Preview {
    HomeView()
}
