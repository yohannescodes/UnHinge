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
    
    private let firebaseManager = FirebaseManager.shared
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