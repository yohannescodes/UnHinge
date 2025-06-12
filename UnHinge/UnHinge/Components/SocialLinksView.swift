import SwiftUI

struct SocialLinksView: View {
    let socialLinks: AppUser.SocialLinks
    
    private func constructURL(scheme: String, host: String, path: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        return components.url
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let instagram = socialLinks.instagram,
               let url = constructURL(scheme: "https", host: "instagram.com", path: "/\(instagram)") {
                Link(destination: url) {
                    Image(systemName: "camera")
                        .foregroundColor(.pink)
                }
            }
            
            if let twitter = socialLinks.twitter,
               let url = constructURL(scheme: "https", host: "twitter.com", path: "/\(twitter)") {
                Link(destination: url) {
                    Image(systemName: "message")
                        .foregroundColor(.blue)
                }
            }
            
            if let tiktok = socialLinks.tiktok,
               let url = constructURL(scheme: "https", host: "tiktok.com", path: "/@\(tiktok)") {
                Link(destination: url) {
                    Image(systemName: "music.note")
                        .foregroundColor(.black)
                }
            }
            
            if let spotify = socialLinks.spotify,
               let url = constructURL(scheme: "https", host: "open.spotify.com", path: "/user/\(spotify)") {
                Link(destination: url) {
                    Image(systemName: "music.note.list")
                        .foregroundColor(.green)
                }
            }
        }
    }
} 
