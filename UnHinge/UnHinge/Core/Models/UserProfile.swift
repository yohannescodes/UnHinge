import Foundation

public struct UserProfile: Identifiable {
    public let id: String
    public let user: User
    public var isOnline: Bool
    public var distance: Double?
    public var age: Int?
    public var lastActive: Date?
    
    public init(user: User, isOnline: Bool = false, distance: Double? = nil, age: Int? = nil, lastActive: Date? = nil) {
        self.id = user.id
        self.user = user
        self.isOnline = isOnline
        self.distance = distance
        self.age = age
        self.lastActive = lastActive
    }
    
    public var displayName: String {
        user.name
    }
    
    public var profileImageURL: String? {
        user.profileImageURL
    }
    
    public var bio: String? {
        user.bio
    }
    
    public var interests: [String] {
        user.interests
    }
    
    public var socialLinks: User.SocialLinks {
        user.socialLinks
    }
    
    public var isVerified: Bool {
        user.isVerified
    }
} 