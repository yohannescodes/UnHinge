import SwiftUI
import FirebaseAuth

// Use your app's custom user model here (replace 'User' with the correct type if needed)
public struct ProfileStatsView: View {
    public let user: AppUser

    public init(user: AppUser) {
        self.user = user
    }

    public var body: some View {
        HStack(spacing: 40) {
            StatView(title: "UserID", value: user.id)
            StatView(title: "Email", value: user.email)
            // TODO: Replace these with real stats from your data model, not Firebase User
            StatView(title: "Matches", value: String(user.analytics.matches)) // Corrected field name
            StatView(title: "Memes", value: String(user.memeDeck.count))
            StatView(title: "Swipes", value: String(user.analytics.totalSwipes)) // Changed to use totalSwipes
        }
        .padding(.vertical)
    }
}
