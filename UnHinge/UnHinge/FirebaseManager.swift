import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
    }
    
    // MARK: - Authentication Methods
    func signInWithApple() async throws -> AuthDataResult {
        // TODO: Implement Apple Sign In
        fatalError("Not implemented")
    }
    
    func signInWithEmail(email: String, password: String) async throws -> AuthDataResult {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    func createUser(email: String, password: String) async throws -> AuthDataResult {
        try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    // MARK: - Firestore Methods
    func saveUserProfile(_ user: User) async throws {
        let db = Firestore.firestore()
        try await db.collection("users").document(user.id).setData(from: user)
    }
    
    func getUserProfile(userId: String) async throws -> User {
        let db = Firestore.firestore()
        let document = try await db.collection("users").document(userId).getDocument()
        return try document.data(as: User.self)
    }
    
    // MARK: - Meme Methods (Modified to work without Storage)
    func addMemeToDeck(userId: String, meme: Meme) async throws {
        let db = Firestore.firestore()
        try await db.collection("users").document(userId).updateData([
            "memeDeck": FieldValue.arrayUnion([try Firestore.Encoder().encode(meme)])
        ])
    }
    
    func removeMemeFromDeck(userId: String, memeId: String) async throws {
        let db = Firestore.firestore()
        let user = try await getUserProfile(userId: userId)
        let updatedDeck = user.memeDeck.filter { $0.id != memeId }
        try await db.collection("users").document(userId).updateData([
            "memeDeck": try Firestore.Encoder().encode(updatedDeck)
        ])
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    var id: String
    var email: String
    var username: String
    var age: Int
    var pronouns: String
    var memePreferences: [String]
    var memeDeck: [Meme]
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case age
        case pronouns
        case memePreferences
        case memeDeck
        case createdAt
    }
}

// MARK: - Meme Model (Modified to work without Storage)
struct Meme: Codable, Identifiable {
    var id: String
    var imageName: String // Changed from URL to String to use local assets
    var tags: [String]
    var uploadedBy: String
    var uploadedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case imageName
        case tags
        case uploadedBy
        case uploadedAt
    }
} 