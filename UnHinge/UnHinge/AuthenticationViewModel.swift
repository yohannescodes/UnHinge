import Foundation
import FirebaseAuth
import SwiftUI

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let firebaseManager = FirebaseManager.shared
    
    init() {
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            if let user = user {
                Task {
                    await self?.fetchUserProfile(userId: user.uid)
                }
            }
        }
    }
    
    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await firebaseManager.signInWithEmail(email: email, password: password)
            await fetchUserProfile(userId: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await firebaseManager.createUser(email: email, password: password)
            
            // Create initial user profile
            let newUser = User(
                id: result.user.uid,
                email: email,
                username: username,
                age: 0, // Will be updated in profile setup
                pronouns: "", // Will be updated in profile setup
                memePreferences: [],
                memeDeck: [],
                createdAt: Date()
            )
            
            try await firebaseManager.saveUserProfile(newUser)
            self.user = newUser
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try firebaseManager.signOut()
            user = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func fetchUserProfile(userId: String) async {
        do {
            user = try await firebaseManager.getUserProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
} 