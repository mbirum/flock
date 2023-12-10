
import Foundation
import SwiftUI
import mbutils

struct MeProfileView: View {
    @Binding var profile: MeProfile
    @State var isUseSuggestedDrivers: Bool = false
    var body: some View {
        NavigationStack {
            RiderDetailsView(rider: $profile.content, isUseSuggestedDrivers: $isUseSuggestedDrivers, isMeProfile: true)
        }
    }
}

//#Preview {
//    MeProfileView(profile: MeProfile(
//        content: Rider(name: "Matt Birum", phoneNumber: "567-204-1135", isDriver: true)))
//}


