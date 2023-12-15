
import Foundation
import SwiftUI

struct PhoneNumberTextField: View {
    @Binding var value: String
    var body: some View {
        TextField("Phone number", text: $value)
            .onChange(of: value) { oldValue, newValue in
                if newValue.count == 4 {
                    let lastCharacter = newValue[3]
                    if lastCharacter != "-" {
                        let firstPart = newValue.prefix(3)
                        value = "\(firstPart)-\(lastCharacter)"
                    }
                    else {
                        if oldValue.count > newValue.count {
                            value = String(newValue.prefix(3))
                        }
                    }
                }
                else if newValue.count == 8 {
                    let lastCharacter = newValue[7]
                    if lastCharacter != "-" {
                        let firstPart = newValue.prefix(7)
                        value = "\(firstPart)-\(lastCharacter)"
                    }
                    else {
                        if oldValue.count > newValue.count {
                            value = String(newValue.prefix(7))
                        }
                    }
                }
                else if newValue.count > 12 {
                    value = oldValue
                }
            }
    }
}

//#Preview {
//    Form {
//        PhoneNumberTextField(value: "")
//    }
//}
