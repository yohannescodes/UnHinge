import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit
import Combine

@MainActor
final class ProfileViewModel: BaseViewModel {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var currentProfile: UserProfile?
    @Published var isUploadingImage = false
    @Published var isVerifying = false
    
    // MARK: - Private Properties
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentTask: Task<Void, Never>?
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadCurrentUser()
        startAnalyticsTracking()
    }
    
    deinit {
        currentTask?.cancel()
        cancellables.forEach { $0.cancel() }
    }
    
    // MARK: - Public Methods
    
    func loadCurrentUser() {
        currentTask?.cancel()
        
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            do {
                self.currentUser = try await self.firebaseService.getUser(userId: userId)
                if !Task.isCancelled, let user = self.currentUser {
                    self.currentProfile = UserProfile(
                        user: user,
                        isOnline: true,
                        lastActive: user.lastActive
                    )
                }
            } catch {
                if !Task.isCancelled {
                    self.handleError(error)
                }
            }
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
            
            await self.loadCurrentUser()
        }
    }
    
    func updatePreferences(
        theme: AppTheme,
        language: String,
        notifications: AppUser.NotificationPreferences,
        privacy: AppUser.PrivacySettings
    ) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let preferences = AppUser.UserPreferences(
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
        let userData: [String: Any] = [
            "name": name,
            "bio": bio as Any,
            "interests": interests,
            "profileImageURL": profileImageURL as Any,
            "socialLinks": [
                "instagram": socialLinks.instagram as Any,
                "twitter": socialLinks.twitter as Any,
                "tiktok": socialLinks.tiktok as Any,
                "spotify": socialLinks.spotify as Any
            ]
        ]
        
        try await firebaseService.updateUser(userId: userId, data: userData)
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
extension AppUser.SocialLinks {
    var dictionary: [String: Any] {
        var dict: [String: Any] = [:]
        if let instagram = instagram { dict["instagram"] = instagram }
        if let twitter = twitter { dict["twitter"] = twitter }
        if let tiktok = tiktok { dict["tiktok"] = tiktok }
        if let spotify = spotify { dict["spotify"] = spotify }
        return dict
    }
}

extension AppUser.UserPreferences {
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
