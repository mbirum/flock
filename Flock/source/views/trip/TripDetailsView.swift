
import Foundation
import SwiftUI

struct TripDetailsView: View {
    @State var trip: Trip
    @State var optimizedTrip: OptimizedTrip?
    @Binding var invalidateView: Bool
    @State var steps: [String] = []
    
    var body: some View {
        VStack {
            List {
                ForEach(trip.riders, id: \.self) { rider in
                    if rider.isDriver {
                        VStack {
                            HStack {
                                Text(rider.name).bold()
                                Image(systemName: "steeringwheel")
                                Spacer()
                            }
                            .font(.system(size: 20))
                            .padding(.bottom,5)
                            ForEach(optimizedTrip?.tripVariations ?? [], id: \.self) { variation in
                                ForEach(variation.routes, id: \.self) { route in
                                    if route.driver.riderId == rider.id {
                                        VStack {
                                            HStack {
                                                Image(systemName: "arrow.turn.right.down")
                                                    .font(.system(size:13))
                                                Text("")
                                                Spacer()
                                            }
                                            .contentShape(Rectangle())

                                            HStack {
                                                if route.to.isDestination {
                                                    Image(systemName: "flag.checkered")
                                                        .font(.system(size:13))
                                                    Text(route.to.locationString).lineLimit(1)
                                                }
                                                else {
                                                    Image(systemName: "circle")
                                                        .padding(.trailing, 1)
                                                        .font(.system(size:11))
                                                    Text(route.to.riderName)
                                                }
                                                Spacer()
                                            }
                                        }
                                        .font(.system(size: 16))
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
            }.listStyle(.plain)
        }
    }
}

#Preview {
    HomeView()
}

