import Foundation
import FirebaseAuth
import SwiftUI
import Combine

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var user: AppUser?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var showMemePreferencesOnboarding = false // Added for onboarding flow
    
    private let firebaseManager = FirebaseManager.shared
    private let firebaseService = FirebaseService.shared // Added for direct service calls if needed
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var currentTask: Task<Void, Never>?
    
    enum AuthError: LocalizedError {
        case invalidEmail
        case weakPassword
        case emailAlreadyInUse
        case userNotFound
        case wrongPassword
        case networkError
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "Please enter a valid email address"
            case .weakPassword:
                return "Password must be at least 6 characters long"
            case .emailAlreadyInUse:
                return "This email is already registered"
            case .userNotFound:
                return "No account found with this email"
            case .wrongPassword:
                return "Incorrect password"
            case .networkError:
                return "Network error. Please check your connection"
            case .unknown(let message):
                return message
            }
        }
    }

    func signInWithApple() async {
        currentTask?.cancel()
        isLoading = true
        errorMessage = nil

        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let result = try await firebaseManager.signInWithApple()
                // After successful sign-in with Apple, Firebase Auth state listener
                // should trigger fetchUserProfile. If not, or if specific actions
                // are needed immediately after Apple Sign-In (e.g., checking if it's a new user),
                // they can be added here.
                // For now, we rely on the auth state listener.
                // If direct profile fetch is needed:
                // if !Task.isCancelled {
                //     await fetchUserProfile(userId: result.user.uid)
                // }
            } catch {
                if !Task.isCancelled {
                    // Apple Sign In can have specific errors, map them if needed
                    // For now, using the generic handler
                    let authError = handleFirebaseError(error) // Or a new specific handler for Apple errors
                    errorMessage = authError.errorDescription ?? "An unknown error occurred during Apple Sign-In."
                }
            }

            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    init() {
        // Listen for authentication state changes
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticated = user != nil
            if let user = user {
                Task { [weak self] in
                    await self?.fetchUserProfile(userId: user.uid)
                }
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
        currentTask?.cancel()
    }
    
    private func handleFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError
        switch nsError.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.wrongPassword.rawValue:
            return .wrongPassword
        case NSURLErrorNotConnectedToInternet:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
    
    func signInWithEmail(email: String, password: String) async {
        currentTask?.cancel()
        isLoading = true
        errorMessage = nil
        
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let result = try await firebaseManager.signInWithEmail(email: email, password: password)
                if !Task.isCancelled {
                    await fetchUserProfile(userId: result.user.uid)
                }
            } catch {
                if !Task.isCancelled {
                    let authError = handleFirebaseError(error)
                    errorMessage = authError.errorDescription
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    func signUp(email: String, password: String, username: String) async {
        currentTask?.cancel()
        isLoading = true
        errorMessage = nil
        
        // Validate input
        guard !email.isEmpty else {
            errorMessage = "Email cannot be empty"
            isLoading = false
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Password cannot be empty"
            isLoading = false
            return
        }
        
        guard !username.isEmpty else {
            errorMessage = "Username cannot be empty"
            isLoading = false
            return
        }
        
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let result = try await firebaseManager.createUser(email: email, password: password)
                
                // Create initial user profile
                let newUser = AppUser(
                    id: result.user.uid,
                    email: email,
                    name: username
                )
                
                try await firebaseManager.saveUserProfile(newUser)
                if !Task.isCancelled {
                    self.user = newUser
                    // After successful profile save, trigger meme preferences onboarding
                    self.showMemePreferencesOnboarding = true
                }
            } catch {
                if !Task.isCancelled {
                    let authError = handleFirebaseError(error)
                    errorMessage = authError.errorDescription
                }
            }
            
            // isLoading should be set to false only after all onboarding steps controlled by this VM are done.
            // For now, let's assume signUp's direct loading state finishes here,
            // and MemePreferencesOnboardingView will manage its own loading state if it calls another async func.
            // Or, theisLoading could be managed more globally.
            // For this change, we'll keep it as is, implying MemePreferencesOnboardingView might need its own isLoading indicator.
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }

    func saveMemePreferences(preferences: [String]) async {
        guard let userId = user?.id else {
            errorMessage = "User not found. Cannot save preferences."
            return
        }

        // It's good practice to manage isLoading for this specific async operation too.
        // However, the global isLoading is currently tied to signUp/signIn.
        // If MemePreferencesOnboardingView has its own loading indicator, that's fine.
        // Otherwise, we might need another @Published var for this specific task.
        // For now, let's clear previous errors and proceed.
        errorMessage = nil
        // isLoading = true // Uncomment if this VM should manage loading for this too

        do {
            // Using "interests" field as per subtask description.
            try await firebaseService.updateUser(userId: userId, data: ["interests": preferences])

            // Optionally, update local user model if it has an 'interests' property
            if !Task.isCancelled {
                 self.user?.interests = preferences // Assuming AppUser has 'interests'
                 self.showMemePreferencesOnboarding = false // Hide onboarding view on success
            }
        } catch {
            if !Task.isCancelled {
                let authError = handleFirebaseError(error) // Or a more generic error handler
                errorMessage = authError.errorDescription ?? "Failed to save meme preferences."
            }
        }

        // if !Task.isCancelled {
        //     isLoading = false // Uncomment if this VM should manage loading for this too
        // }
    }
    
    func signOut() {
        do {
            try firebaseManager.signOut()
            user = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
    
    private func fetchUserProfile(userId: String) async {
        do {
            let profile = try await firebaseManager.getUserProfile(userId: userId)
            if !Task.isCancelled {
                user = profile
            }
        } catch {
            if !Task.isCancelled {
                errorMessage = "Failed to load profile: \(error.localizedDescription)"
            }
        }
    }
} 