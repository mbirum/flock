
import Foundation
import SwiftUI

struct AddButton: View {
    
    var text = "Add"
    var destination: AnyView
    
    init(_ text: String, destination: AnyView) {
        self.text = text
        self.destination = destination
    }
    
    var body: some View {
        VStack {
            HStack {
                NavigationLink(destination: destination) {
                    HStack {
                        Spacer()
                        Text(text)
                        Spacer()
                    }
                    .padding(.vertical, 15)
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color("AccentColor"))
            .foregroundStyle(.white)
            .cornerRadius(8)
        }
        .frame(height: 75)
        .padding(.horizontal, 25)
    }
}
