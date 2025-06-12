import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseStorage
import Combine

@MainActor
class ProfileViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isUploadingImage = false
    @Published var isVerifying = false
    
    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadCurrentUser()
        startAnalyticsTracking()
    }
    
    // MARK: - Public Methods
    
    func loadCurrentUser() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        performTask {
            self.currentUser = try await self.firebaseService.getUser(userId: userId)
        }
    }
    
    func updateProfile(
        name: String,
        bio: String?,
        interests: [String],
        profileImage: UIImage?,
        socialLinks: User.SocialLinks
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        performTask {
            if let image = profileImage {
                self.isUploadingImage = true
                let imageData = try await self.firebaseService.uploadProfileImage(userId: userId, image: image)
                self.isUploadingImage = false
                
                try await self.saveProfile(
                    userId: userId,
                    name: name,
                    bio: bio,
                    interests: interests,
                    profileImageURL: imageData.url,
                    socialLinks: socialLinks
                )
            } else {
                try await self.saveProfile(
                    userId: userId,
                    name: name,
                    bio: bio,
                    interests: interests,
                    profileImageURL: nil,
                    socialLinks: socialLinks
                )
            }
        }
    }
    
    func updatePreferences(
        theme: User.AppTheme,
        language: String,
        notifications: User.NotificationPreferences,
        privacy: User.PrivacySettings
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let preferences = User.UserPreferences(
            theme: theme,
            language: language,
            notifications: notifications,
            privacy: privacy
        )
        
        performTask {
            try await self.firebaseService.updateUser(userId: userId, data: [
                "preferences": preferences.dictionary
            ])
            self.currentUser?.preferences = preferences
        }
    }
    
    func requestVerification() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isVerifying = true
        clearError()
        
        Task {
            do {
                // Simulate verification process
                try await Task.sleep(nanoseconds: 2 * 1_000_000_000)
                
                try await firebaseService.updateUser(userId: userId, data: [
                    "isVerified": true,
                    "verificationDate": FieldValue.serverTimestamp()
                ])
                
                currentUser?.isVerified = true
                currentUser?.verificationDate = Date()
            } catch {
                handleError(error)
            }
            isVerifying = false
        }
    }
    
    func deleteAccount() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        performTask {
            try await self.firebaseService.deleteUser(userId: userId)
            try await self.firebaseService.deleteAccount()
        }
    }
    
    // MARK: - Private Methods
    
    private func saveProfile(
        userId: String,
        name: String,
        bio: String?,
        interests: [String],
        profileImageURL: String?,
        socialLinks: User.SocialLinks
    ) async throws {
        var data: [String: Any] = [
            "name": name,
            "interests": interests,
            "socialLinks": socialLinks.dictionary
        ]
        
        if let bio = bio {
            data["bio"] = bio
        }
        
        if let profileImageURL = profileImageURL {
            data["profileImageURL"] = profileImageURL
        }
        
        try await firebaseService.updateUser(userId: userId, data: data)
        
        currentUser?.name = name
        currentUser?.bio = bio
        currentUser?.interests = interests
        currentUser?.profileImageURL = profileImageURL
        currentUser?.socialLinks = socialLinks
    }
    
    private func startAnalyticsTracking() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Task {
            do {
                try await firebaseService.updateLastActive(userId: userId)
                
                let hour = Calendar.current.component(.hour, from: Date())
                try await firebaseService.trackActiveHour(userId: userId, hour: hour)
            } catch {
                print("Error tracking analytics: \(error)")
            }
        }
    }
}

// MARK: - Dictionary Extensions
extension User.SocialLinks {
    var dictionary: [String: Any] {
        var dict: [String: Any] = [:]
        if let instagram = instagram { dict["instagram"] = instagram }
        if let twitter = twitter { dict["twitter"] = twitter }
        if let tiktok = tiktok { dict["tiktok"] = tiktok }
        if let spotify = spotify { dict["spotify"] = spotify }
        return dict
    }
}

extension User.UserPreferences {
    var dictionary: [String: Any] {
        [
            "theme": theme.rawValue,
            "language": language,
            "notifications": [
                "newMatches": notifications.newMatches,
                "messages": notifications.messages,
                "likes": notifications.likes,
                "profileViews": notifications.profileViews,
                "marketing": notifications.marketing
            ],
            "privacy": [
                "showOnlineStatus": privacy.showOnlineStatus,
                "showLastActive": privacy.showLastActive,
                "showDistance": privacy.showDistance,
                "showAge": privacy.showAge
            ]
        ]
    }
} 