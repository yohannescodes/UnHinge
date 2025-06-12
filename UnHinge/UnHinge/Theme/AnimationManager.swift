import SwiftUI

struct AppAnimation {
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let easeOut = Animation.easeOut(duration: 0.2)
    static let easeIn = Animation.easeIn(duration: 0.2)
    static let interactive = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.5)
    
    struct Timing {
        static let short = 0.2
        static let medium = 0.3
        static let long = 0.5
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(AppAnimation.spring, value: configuration.isPressed)
    }
}

struct FadeTransition: ViewModifier {
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isPresented ? 1 : 0)
            .animation(AppAnimation.spring, value: isPresented)
    }
}

struct SlideTransition: ViewModifier {
    let isPresented: Bool
    let edge: Edge
    
    func body(content: Content) -> some View {
        content
            .offset(x: isPresented ? 0 : (edge == .leading ? -UIScreen.main.bounds.width : UIScreen.main.bounds.width))
            .animation(AppAnimation.spring, value: isPresented)
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

extension View {
    func fadeTransition(isPresented: Bool) -> some View {
        modifier(FadeTransition(isPresented: isPresented))
    }
    
    func slideTransition(isPresented: Bool, edge: Edge = .trailing) -> some View {
        modifier(SlideTransition(isPresented: isPresented, edge: edge))
    }
    
    func shake(amount: CGFloat = 10, shakesPerUnit: Int = 3) -> some View {
        modifier(ShakeEffect(amount: amount, shakesPerUnit: shakesPerUnit, animatableData: 1))
    }
    
    func scaleButton() -> some View {
        buttonStyle(ScaleButtonStyle())
    }
} 