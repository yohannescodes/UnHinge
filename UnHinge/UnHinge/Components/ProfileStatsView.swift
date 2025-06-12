import SwiftUI

public struct ProfileStatsView: View {
    public let user: User
    
    public init(user: User) {
        self.user = user
    }
    
    public var body: some View {
        HStack(spacing: 40) {
            StatView(title: "Matches", value: "\(user.matches?.count ?? 0)")
            StatView(title: "Memes", value: "\(user.memes?.count ?? 0)")
            StatView(title: "Likes", value: "\(user.analytics?.totalLikes ?? 0)")
        }
        .padding(.vertical)
    }
} 