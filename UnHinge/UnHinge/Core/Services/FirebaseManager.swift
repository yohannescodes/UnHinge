import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
    }
    
    // MARK: - Authentication Methods
    func signInWithApple() async throws -> AuthDataResult {
        try await FirebaseService.shared.signInWithApple()
    }
    
    func signInWithEmail(email: String, password: String) async throws -> AuthDataResult {
        do {
            return try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to sign in: \(error.localizedDescription)"])
        }
    }
    
    func createUser(email: String, password: String) async throws -> AuthDataResult {
        do {
            return try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user: \(error.localizedDescription)"])
        }
    }
    
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to sign out: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Firestore Methods
    func saveUserProfile(_ user: AppUser) async throws {
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(user.id).setData(from: user)
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save user profile: \(error.localizedDescription)"])
        }
    }
    
    func getUserProfile(userId: String) async throws -> AppUser {
        let db = Firestore.firestore()
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            guard document.exists else {
                throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
            }
            return try document.data(as: AppUser.self)
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get user profile: \(error.localizedDescription)"])
        }
    }
    
    // MARK: - Meme Methods
    func addMemeToDeck(userId: String, meme: Meme) async throws {
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(userId).updateData([
                "memes": FieldValue.arrayUnion([try Firestore.Encoder().encode(meme)])
            ])
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to add meme to deck: \(error.localizedDescription)"])
        }
    }
    
    func removeMemeFromDeck(userId: String, memeId: String) async throws {
        let db = Firestore.firestore()
        do {
            let user = try await getUserProfile(userId: userId)
            let updatedDeck = user.memeDeck.filter { $0.id != memeId }
            try await db.collection("users").document(userId).updateData([
                "memeDeck": try Firestore.Encoder().encode(updatedDeck)
            ])
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to remove meme from deck: \(error.localizedDescription)"])
        }
    }
    
    func updateLastActive(userId: String) async throws {
        let db = Firestore.firestore()
        do {
            try await db.collection("users").document(userId).updateData([
                "lastActive": FieldValue.serverTimestamp()
            ])
        } catch {
            throw NSError(domain: "FirebaseManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update last active: \(error.localizedDescription)"])
        }
    }
}
