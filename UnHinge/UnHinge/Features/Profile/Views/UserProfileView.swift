import SwiftUI

@MainActor // Mark UserProfileView as @MainActor
public struct UserProfileView: View {
    let profile: UserProfile
    @State private var isEditing = false
    
    // Initializer will also be MainActor isolated due to struct annotation
    public init(profile: UserProfile) {
        self.profile = profile
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 12) {
                    if let imageURL = profile.profileImageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text(profile.displayName)
                            .font(.title2)
                            .bold()
                        
                        if profile.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if let bio = profile.bio {
                        Text(bio)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // Online Status and Last Active
                HStack {
                    Circle()
                        .fill(profile.isOnline ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(profile.isOnline ? "Online" : "Offline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let lastActive = profile.lastActive {
                        Text("• Last active \(lastActive.timeAgoDisplay())")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Interests
                if !profile.interests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Interests")
                            .font(.headline)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(profile.interests, id: \.self) { interest in
                                Text(interest)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Social Links
                if !profile.socialLinks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Social Links")
                            .font(.headline)
                        
                        HStack(spacing: 16) {
                            if let instagram = profile.socialLinks.instagram {
                                SocialLinkButton(platform: "Instagram", url: instagram)
                            }
                            if let twitter = profile.socialLinks.twitter {
                                SocialLinkButton(platform: "Twitter", url: twitter)
                            }
                            if let tiktok = profile.socialLinks.tiktok {
                                SocialLinkButton(platform: "TikTok", url: tiktok)
                            }
                            if let spotify = profile.socialLinks.spotify {
                                SocialLinkButton(platform: "Spotify", url: spotify)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isEditing = true }) {
                    Image(systemName: "pencil")
                }
            }
        }
    }
}

private struct SocialLinkButton: View {
    let platform: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            VStack {
                Image(systemName: iconName)
                    .font(.title2)
                Text(platform)
                    .font(.caption)
            }
        }
    }
    
    private var iconName: String {
        switch platform.lowercased() {
        case "instagram": return "camera"
        case "twitter": return "message"
        case "tiktok": return "music.note"
        case "spotify": return "music.note.list"
        default: return "link"
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal).size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = layout(sizes: sizes, proposal: proposal).positions
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: positions[index], proposal: .unspecified)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> (positions: [CGPoint], size: CGSize) {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        var positions: [CGPoint] = []
        
        for size in sizes {
            if currentX + size.width > width {
                currentX = 0
                currentY = maxY + spacing
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            maxY = max(maxY, currentY + size.height)
        }
        
        return (positions, CGSize(width: width, height: maxY))
    }
}

private extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: self, to: now)
        
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

private extension User.SocialLinks {
    var isEmpty: Bool {
        instagram == nil && twitter == nil && tiktok == nil && spotify == nil
    }
} 