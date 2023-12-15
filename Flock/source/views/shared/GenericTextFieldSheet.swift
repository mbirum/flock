
import Foundation
import SwiftUI

struct GenericTextFieldSheet: View {
    @State var label: String
    @Binding var field: String
    @Binding var isPresent: Bool
    @FocusState var isLoaded: Bool
    
    var body: some View {
        VStack {
            HStack {
                TextField(label, text: $field)
                    .focused($isLoaded)
                    .frame(height: 40)
                    .padding(18)
                    .padding(.top, 5)
                    .onAppear(perform: {
                        self.isLoaded = true
                    })
                
                Button("Done", action: {
                    isPresent.toggle()
                })
                .padding(.top, 23)
                .padding(.trailing, 18)
                .padding(.bottom, 18)
            }
            Divider()
            Spacer()
        }
        
    }
}
