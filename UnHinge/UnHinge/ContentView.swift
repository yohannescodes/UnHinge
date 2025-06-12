import SwiftUI

struct Match: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    var isNew: Bool
}

struct Conversation: Identifiable {
    let id = UUID()
    let match: Match
    var messages: [Message]
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isSentByUser: Bool
}

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
