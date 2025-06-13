import Foundation
import FirebaseFirestore
import FirebaseFirestoreInternal

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
        return [
            "id": id,
            "email": email,
            "name": name,
            "bio": bio as Any,
            "profileImageURL": profileImageURL as Any,
            "interests": interests,
            "isVerified": isVerified,
            "verificationDate": verificationDate?.timeIntervalSince1970 as Any,
            "lastActive": lastActive.timeIntervalSince1970,
            "memeDeck": memeDeck.map { $0.dictionary },
            "preferences": [
                "theme": preferences.theme.rawValue,
                "language": preferences.language,
                "notifications": [
                    "newMatches": preferences.notifications.newMatches,
                    "messages": preferences.notifications.messages,
                    "likes": preferences.notifications.likes,
                    "profileViews": preferences.notifications.profileViews,
                    "marketing": preferences.notifications.marketing
                ],
                "privacy": [
                    "showOnlineStatus": preferences.privacy.showOnlineStatus,
                    "showLastActive": preferences.privacy.showLastActive,
                    "showDistance": preferences.privacy.showDistance,
                    "showAge": preferences.privacy.showAge
                ]
            ],
            "socialLinks": [
                "instagram": socialLinks.instagram as Any,
                "twitter": socialLinks.twitter as Any,
                "tiktok": socialLinks.tiktok as Any,
                "spotify": socialLinks.spotify as Any
            ],
            "analytics": [
                "activeHours": analytics.activeHours,
                "totalSwipes": analytics.totalSwipes,
                "matches": analytics.matches,
                "messagesSent": analytics.messagesSent,
                "memesShared": analytics.memesShared
            ]
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let email = dictionary["email"] as? String,
              let name = dictionary["name"] as? String else {
            return nil
        }
        
        let bio = dictionary["bio"] as? String
        let profileImageURL = dictionary["profileImageURL"] as? String
        let interests = dictionary["interests"] as? [String] ?? []
        let isVerified = dictionary["isVerified"] as? Bool ?? false
        
        var verificationDate: Date?
        if let timestamp = dictionary["verificationDate"] as? TimeInterval {
            verificationDate = Date(timeIntervalSince1970: timestamp)
        }
        
        var lastActive = Date()
        if let timestamp = dictionary["lastActive"] as? TimeInterval {
            lastActive = Date(timeIntervalSince1970: timestamp)
        }
        
        let memeDeckData = dictionary["memeDeck"] as? [[String: Any]] ?? []
        let memeDeck = memeDeckData.compactMap { Meme(dictionary: $0) }
        
        // Parse preferences
        let preferencesDict = dictionary["preferences"] as? [String: Any] ?? [:]
        let theme = AppTheme(rawValue: preferencesDict["theme"] as? String ?? "system") ?? .system
        let language = preferencesDict["language"] as? String ?? "en"
        
        // Parse notifications
        let notificationsDict = preferencesDict["notifications"] as? [String: Bool] ?? [:]
        let notifications = NotificationPreferences(
            newMatches: notificationsDict["newMatches"] ?? true,
            messages: notificationsDict["messages"] ?? true,
            likes: notificationsDict["likes"] ?? true,
            profileViews: notificationsDict["profileViews"] ?? true,
            marketing: notificationsDict["marketing"] ?? false
        )
        
        // Parse privacy settings
        let privacyDict = preferencesDict["privacy"] as? [String: Bool] ?? [:]
        let privacy = PrivacySettings(
            showOnlineStatus: privacyDict["showOnlineStatus"] ?? true,
            showLastActive: privacyDict["showLastActive"] ?? true,
            showDistance: privacyDict["showDistance"] ?? true,
            showAge: privacyDict["showAge"] ?? true
        )
        
        let preferences = UserPreferences(
            theme: theme,
            language: language,
            notifications: notifications,
            privacy: privacy
        )
        
        // Parse social links
        let socialLinksDict = dictionary["socialLinks"] as? [String: String] ?? [:]
        let socialLinks = SocialLinks(
            instagram: socialLinksDict["instagram"],
            twitter: socialLinksDict["twitter"],
            tiktok: socialLinksDict["tiktok"],
            spotify: socialLinksDict["spotify"]
        )
        
        // Parse analytics
        let analyticsDict = dictionary["analytics"] as? [String: Any] ?? [:]
        let analytics = UserAnalytics(
            activeHours: analyticsDict["activeHours"] as? [Int: Int] ?? [:],
            totalSwipes: analyticsDict["totalSwipes"] as? Int ?? 0,
            matches: analyticsDict["matches"] as? Int ?? 0,
            messagesSent: analyticsDict["messagesSent"] as? Int ?? 0,
            memesShared: analyticsDict["memesShared"] as? Int ?? 0
        )
        
        self.init(
            id: id,
            email: email,
            name: name,
            bio: bio,
            profileImageURL: profileImageURL,
            interests: interests,
            isVerified: isVerified,
            verificationDate: verificationDate,
            lastActive: lastActive,
            memeDeck: memeDeck,
            preferences: preferences,
            socialLinks: socialLinks,
            analytics: analytics
        )
    }
    
    private static func convertTimestampsToDate(_ value: Any) -> Any {
        if let dict = value as? [String: Any] {
            var newDict = [String: Any]()
            for (k, v) in dict {
                newDict[k] = convertTimestampsToDate(v)
            }
            return newDict
        } else if let array = value as? [Any] {
            return array.map { convertTimestampsToDate($0) }
        } else if let timestamp = value as? Timestamp {
            return timestamp.dateValue()
        } else if let firTimestamp = value as? NSObject, NSStringFromClass(type(of: firTimestamp)).contains("FIRTimestamp") {
            return (firTimestamp.value(forKey: "dateValue") as? Date) ?? firTimestamp
        } else {
            return value
        }
    }
}

