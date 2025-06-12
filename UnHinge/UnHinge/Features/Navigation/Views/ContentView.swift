import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // If authenticated, decide whether to show onboarding or main app
                if authViewModel.showMemePreferencesOnboarding {
                    MemePreferencesOnboardingView()
                        .environmentObject(authViewModel)
                } else {
                    MainTabView()
                        .environmentObject(authViewModel)
                }
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
        // Alternative: Using a sheet or fullScreenCover on MainTabView
        // This might be cleaner if MainTabView is the primary view post-auth.
        // However, the above Group logic directly switches the view,
        // which is also a valid approach.
        //
        // Example using .fullScreenCover on the Group if we want to overlay:
        // .fullScreenCover(isPresented: $authViewModel.showMemePreferencesOnboarding) {
        //     MemePreferencesOnboardingView()
        //         .environmentObject(authViewModel)
        // }
        // For this implementation, the direct view switch in the Group is chosen.
    }
}

#Preview {
    ContentView() 
}
