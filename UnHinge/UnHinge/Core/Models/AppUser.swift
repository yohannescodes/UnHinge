import Foundation
import FirebaseFirestore

public typealias User = AppUser

public enum AppTheme: String, Codable, CaseIterable {
    case light
    case dark
    case system
}

public struct AppUser: Codable, Identifiable, Equatable { // Added Equatable
    public let id: String
    public let email: String
    public var name: String
    public var bio: String?
    public var profileImageURL: String?
    public var interests: [String]
    public var isVerified: Bool
    public var verificationDate: Date?
    public var lastActive: Date
    public var memeDeck: [Meme]
    public var preferences: UserPreferences
    public var socialLinks: SocialLinks
    public var analytics: UserAnalytics
    
    public struct UserPreferences: Codable {
        public var theme: AppTheme
        public var language: String
        public var notifications: NotificationPreferences
        public var privacy: PrivacySettings
        
        public init(theme: AppTheme = .system,
                   language: String = "en",
                   notifications: NotificationPreferences = .init(),
                   privacy: PrivacySettings = .init()) {
            self.theme = theme
            self.language = language
            self.notifications = notifications
            self.privacy = privacy
        }
    }
    
    public struct NotificationPreferences: Codable {
        public var newMatches: Bool
        public var messages: Bool
        public var likes: Bool
        public var profileViews: Bool
        public var marketing: Bool
        
        public init(newMatches: Bool = true,
                   messages: Bool = true,
                   likes: Bool = true,
                   profileViews: Bool = true,
                   marketing: Bool = false) {
            self.newMatches = newMatches
            self.messages = messages
            self.likes = likes
            self.profileViews = profileViews
            self.marketing = marketing
        }
    }
    
    public struct PrivacySettings: Codable {
        public var showOnlineStatus: Bool
        public var showLastActive: Bool
        public var showDistance: Bool
        public var showAge: Bool
        
        public init(showOnlineStatus: Bool = true,
                   showLastActive: Bool = true,
                   showDistance: Bool = true,
                   showAge: Bool = true) {
            self.showOnlineStatus = showOnlineStatus
            self.showLastActive = showLastActive
            self.showDistance = showDistance
            self.showAge = showAge
        }
    }
    
    public struct SocialLinks: Codable {
        public var instagram: String?
        public var twitter: String?
        public var tiktok: String?
        public var spotify: String?
        
        public init(instagram: String? = nil,
                   twitter: String? = nil,
                   tiktok: String? = nil,
                   spotify: String? = nil) {
            self.instagram = instagram
            self.twitter = twitter
            self.tiktok = tiktok
            self.spotify = spotify
        }
    }
    
    public struct UserAnalytics: Codable {
        public var activeHours: [Int: Int]
        public var totalSwipes: Int
        public var matches: Int
        public var messagesSent: Int
        public var memesShared: Int
        
        public init(activeHours: [Int: Int] = [:],
                   totalSwipes: Int = 0,
                   matches: Int = 0,
                   messagesSent: Int = 0,
                   memesShared: Int = 0) {
            self.activeHours = activeHours
            self.totalSwipes = totalSwipes
            self.matches = matches
            self.messagesSent = messagesSent
            self.memesShared = memesShared
        }
    }
    
    public init(id: String,
                email: String,
                name: String,
                bio: String? = nil,
                profileImageURL: String? = nil,
                interests: [String] = [],
                isVerified: Bool = false,
                verificationDate: Date? = nil,
                lastActive: Date = Date(),
                memeDeck: [Meme] = [],
                preferences: UserPreferences = .init(),
                socialLinks: SocialLinks = .init(),
                analytics: UserAnalytics = .init()) {
        self.id = id
        self.email = email
        self.name = name
        self.bio = bio
        self.profileImageURL = profileImageURL
        self.interests = interests
        self.isVerified = isVerified
        self.verificationDate = verificationDate
        self.lastActive = lastActive
        self.memeDeck = memeDeck
        self.preferences = preferences
        self.socialLinks = socialLinks
        self.analytics = analytics
    }

    // Equatable conformance
    public static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Firestore Conversion
extension AppUser {
    var dictionary: [String: Any] {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        let decoder = JSONDecoder()
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let user = try? decoder.decode(AppUser.self, from: data) else {
            return nil
        }
        self = user
    }
}