import SwiftUI

struct ThemeColors {
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let background = Color("Background")
    static let surface = Color("Surface")
    static let text = Color("Text")
    static let accent = Color("Accent")
    
    static let memeCardBackground = Color("MemeCardBackground")
    static let memeCardBorder = Color("MemeCardBorder")
    
    static let buttonBackground = Color("ButtonBackground")
    static let buttonText = Color("ButtonText")
    
    static let error = Color("Error")
    static let success = Color("Success")
}

struct ThemeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(ThemeColors.background)
            .foregroundColor(ThemeColors.text)
    }
}

extension View {
    func withAppTheme() -> some View {
        modifier(ThemeModifier())
    }
} 
