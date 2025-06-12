import SwiftUI
import FirebaseCore

@main
struct UnHinge: App {
    init() {
        FirebaseManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


