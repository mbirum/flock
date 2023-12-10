
import Foundation
import SwiftUI

struct CustomNavTitle: View {
    @Binding var title: String
    @State var divide: Bool
    @State var isEditable: Bool
    @State var onTap: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .padding(.leading, 15)
                    .padding(.top, 10)
                    .font(.system(size: 32))
                    .bold()
                    .lineLimit(2)
                if isEditable {
                    Image(systemName: "pencil")
                        .foregroundStyle(.gray)
                        .opacity(0.8)
                        .font(.system(size: 20.0))
                        .padding(.top, 18)
                }
                Spacer()
            }
            .onTapGesture {
                onTap()
            }
            if (divide) {
                Divider()
            }
        }
    }
}
