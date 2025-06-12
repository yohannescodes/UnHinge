import Foundation
import FirebaseFirestoreSwift

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    var bio: String?
    var profileImageURL: String?
    var interests: [String]?
    var matches: [String]?
    var memes: [String]?
    var likes: Int?
    var showMe: Bool
    var minAge: Int
    var maxAge: Int
    var maxDistance: Int
    var isVerified: Bool
    var verificationDate: Date?
    var socialLinks: SocialLinks?
    var analytics: UserAnalytics?
    var preferences: UserPreferences?
    var lastActive: Date?
    
    struct SocialLinks: Codable {
        var instagram: String?
        var twitter: String?
        var tiktok: String?
        var spotify: String?
    }
    
    struct UserAnalytics: Codable {
        var profileViews: Int
        var memeViews: Int
        var totalLikes: Int
        var matchRate: Double
        var responseRate: Double
        var averageResponseTime: TimeInterval
        var activeHours: [Int: Int] // hour: count
    }
    
    struct UserPreferences: Codable {
        var theme: AppTheme
        var language: String
        var notifications: NotificationPreferences
        var privacy: PrivacySettings
    }
    
    enum AppTheme: String, Codable {
        case system
        case light
        case dark
    }
    
    struct NotificationPreferences: Codable {
        var newMatches: Bool
        var messages: Bool
        var likes: Bool
        var profileViews: Bool
        var marketing: Bool
    }
    
    struct PrivacySettings: Codable {
        var showOnlineStatus: Bool
        var showLastActive: Bool
        var showDistance: Bool
        var showAge: Bool
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case profileImageURL
        case interests
        case matches
        case memes
        case likes
        case showMe
        case minAge
        case maxAge
        case maxDistance
        case isVerified
        case verificationDate
        case socialLinks
        case analytics
        case preferences
        case lastActive
    }
} 