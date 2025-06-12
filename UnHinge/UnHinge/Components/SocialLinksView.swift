import SwiftUI

public struct SocialLinksView: View {
    public let socialLinks: User.SocialLinks
    
    public init(socialLinks: User.SocialLinks) {
        self.socialLinks = socialLinks
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            if let instagram = socialLinks.instagram {
                Link(destination: URL(string: "https://instagram.com/\(instagram)")!) {
                    Image("instagram")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            if let twitter = socialLinks.twitter {
                Link(destination: URL(string: "https://twitter.com/\(twitter)")!) {
                    Image("twitter")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            if let tiktok = socialLinks.tiktok {
                Link(destination: URL(string: "https://tiktok.com/@\(tiktok)")!) {
                    Image("tiktok")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            if let spotify = socialLinks.spotify {
                Link(destination: URL(string: "https://open.spotify.com/user/\(spotify)")!) {
                    Image("spotify")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
} 