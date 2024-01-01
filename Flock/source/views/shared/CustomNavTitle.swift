
import Foundation
import SwiftUI

struct CustomNavTitle<Content: View>: View {
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack {
            content
        }
    }
}

struct DividerModifier: ViewModifier {
    func body(content: Content) -> some View {
        VStack {
            content
            Divider()
        }
    }
}

struct EditableModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            content
            Image(systemName: "pencil")
                .fontWeight(.thin)
                .foregroundStyle(.gray)
                .opacity(0.8)
                .font(.system(size: 18.0))
                .padding(.top, 18)
            Spacer()
        }
    }
}

struct DefaultPaddingModifier: ViewModifier {
    func body(content: Content) -> some View {
        HStack {
            content
            Spacer()
        }
    }
}

struct DefaultNavTitleText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    var body: some View {
        Text(text)
            .padding(.leading, 15)
            .padding(.top, 10)
            .font(.system(size: 28))
            .bold()
            .lineLimit(1)
    }
}

extension View {
    func editable(code: @escaping () -> Void) -> some View {
        ModifiedContent(content: self, modifier: EditableModifier())
            .onTapGesture {
                code()
            }
    }
    
    func divider() -> some View {
        ModifiedContent(content: self, modifier: DividerModifier())
    }
    
    func defaultPadding() -> some View {
        ModifiedContent(content: self, modifier: DefaultPaddingModifier())
    }
}
