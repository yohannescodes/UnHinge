import SwiftUI

public struct ProfileHeaderView: View {
    public let user: AppUser
    @Binding public var showingVerification: Bool
    
    public init(user: AppUser, showingVerification: Binding<Bool>) {
        self.user = user
        self._showingVerification = showingVerification
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                if let imageURL = user.profileImageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                            .frame(width: 120, height: 120)
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.gray)
                }
                if user.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.blue)
                        .background(Color.white)
                        .clipShape(Circle())
                }
            }
            HStack {
                Text(user.name)
                    .font(.title2)
                    .bold()
                if !user.isVerified {
                    Button(action: { showingVerification = true }) {
                        Text("Verify")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
            if let bio = user.bio {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            SocialLinksView(socialLinks: user.socialLinks)
        }
        .padding()
    }
} 