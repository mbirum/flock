
import Foundation
import SwiftUI

struct TripStepsView: View {
    @State var trip: Trip
    @State var optimizedTrip: OptimizedTrip?
    @Binding var invalidateView: Bool
    @State var steps: [String] = []
    
    var body: some View {
        VStack {
            List {
                ForEach(optimizedTrip?.tripVariations ?? [], id: \.self) { variation in
                    VStack {
                        let driverName = variation.driver?.riderName ?? "Unknown"
                        HStack {
                            Text(driverName).bold()
                            Image(systemName: "steeringwheel")
                                .fontWeight(.thin)
                            Text(variation.totalTime.toString())
                                .font(.system(size: 14))
                                .baselineOffset(-4.0)
                            Spacer()
                        }
                        .font(.system(size: 20))
                        .padding(.bottom,5)
                        ForEach(variation.routes, id: \.self) { route in
                            VStack {
                                HStack {
                                    Image(systemName: "arrow.turn.right.down")
                                        .fontWeight(.thin)
                                        .font(.system(size:13))
                                    Text("")
                                    Spacer()
                                }
                                .contentShape(Rectangle())

                                HStack {
                                    if route.to.isDestination {
                                        Image(systemName: "flag.checkered")
                                            .fontWeight(.thin)
                                            .font(.system(size:13))
                                        Text(route.to.locationString)
                                            .lineLimit(1)
                                            .bold()
                                        Text("-  \(route.route?.expectedTravelTime.toString() ?? "")")
                                            .bold()
                                            .font(.system(size: 14))
                                            .baselineOffset(-4.0)
                                    }
                                    else {
                                        Image(systemName: "circle")
                                            .fontWeight(.thin)
                                            .padding(.trailing, 1)
                                            .font(.system(size:11))
                                        Text(route.to.riderName)
                                            .lineLimit(1)
                                        Text("-  \(route.route?.expectedTravelTime.toString() ?? "")")
                                            .font(.system(size: 14))
                                            .baselineOffset(-4.0)
                                    }
                                    Spacer()
                                }
                            }
                            .font(.system(size: 16))
                        }
                    }
                }
                
            }.listStyle(.plain)
        }
    }
}

#Preview {
    HomeView()
}

