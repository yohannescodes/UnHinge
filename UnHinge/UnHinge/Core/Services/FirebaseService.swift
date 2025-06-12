import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import Combine
import UIKit

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    @Published private(set) var currentUser: AppUser?
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    private init() {
        setupAuthStateHandler()
    }
    
    private func setupAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let user = user {
                Task {
                    do {
                        self?.currentUser = try await self?.getUser(userId: user.uid)
                    } catch {
                        print("Error fetching user: \(error)")
                    }
                }
            } else {
                self?.currentUser = nil
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Configuration
    
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
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
    }
    
    // MARK: - User Operations
    
    func getUser(userId: String) async throws -> AppUser? {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let dict = document.data() else { return nil }
        return AppUser(dictionary: dict)
    }
    
    func saveUserProfile(_ user: AppUser) async throws {
        try await db.collection("users").document(user.id).setData(from: user)
    }
    
    func updateUser(userId: String, data: [String: Any]) async throws {
        try await db.collection("users").document(userId).updateData(data)
    }
    
    func deleteUser(userId: String) async throws {
        try await db.collection("users").document(userId).delete()
    }
    
    // MARK: - Profile Image Operations
    
    func uploadProfileImage(userId: String, image: UIImage) async throws -> (url: String, width: Double, height: Double) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image"])
        }
        
        let imageRef = storage.reference().child("profile_images/\(userId).jpg")
        _ = try await imageRef.putDataAsync(imageData)
        let url = try await imageRef.downloadURL()
        
        return (
            url: url.absoluteString,
            width: Double(image.size.width),
            height: Double(image.size.height)
        )
    }
    
    // MARK: - Meme Operations
    
    func addMemeToDeck(userId: String, meme: Meme) async throws {
        try await db.collection("users").document(userId).updateData([
            "memeDeck": FieldValue.arrayUnion([try Firestore.Encoder().encode(meme)])
        ])
    }
    
    func removeMemeFromDeck(userId: String, memeId: String) async throws {
        let user = try await getUser(userId: userId)
        guard let user = user else { return }
        let updatedDeck = user.memeDeck.filter { $0.id != memeId }
        try await db.collection("users").document(userId).updateData([
            "memeDeck": try Firestore.Encoder().encode(updatedDeck)
        ])
    }
    
    func uploadMeme(image: UIImage, caption: String, tags: [String], userId: String) async throws -> Meme {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image"])
        }
        
        let memeId = UUID().uuidString
        let imageRef = storage.reference().child("memes/\(memeId).jpg")
        _ = try await imageRef.putDataAsync(imageData)
        let url = try await imageRef.downloadURL()
        
        let meme = Meme(
            id: memeId,
            imageName: url.absoluteString,
            tags: tags,
            uploadedBy: userId,
            uploadedAt: Date(),
            likes: 0,
            views: 0
        )
        
        try await db.collection("memes").document(memeId).setData(from: meme)
        return meme
    }
    
    // MARK: - Analytics Operations
    
    func updateLastActive(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "lastActive": FieldValue.serverTimestamp()
        ])
    }
    
    func trackActiveHour(userId: String, hour: Int) async throws {
        try await db.collection("users").document(userId).updateData([
            "analytics.activeHours.\(hour)": FieldValue.increment(Int64(1))
        ])
    }
    
    // MARK: - Messaging Operations
    
    func getMessages(for conversationId: String) -> AnyPublisher<[Message], Error> {
        Future<[Message], Error> { promise in
            self.db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .order(by: "timestamp", descending: false)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    let messages = documents.compactMap { document -> Message? in
                        try? document.data(as: Message.self)
                    }
                    
                    promise(.success(messages))
                }
        }
        .eraseToAnyPublisher()
    }
    
    func sendMessage(_ message: Message, in conversationId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            do {
                try self.db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .document(message.id)
                    .setData(from: message) { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            // Update conversation's lastUpdated timestamp
                            self.db.collection("conversations")
                                .document(conversationId)
                                .updateData(["lastUpdated": Date()]) { error in
                                    if let error = error {
                                        promise(.failure(error))
                                    } else {
                                        promise(.success(()))
                                    }
                                }
                        }
                    }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func markMessageAsRead(_ messageId: String, in conversationId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            self.db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(messageId)
                .updateData(["isRead": true]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Chat Methods
    
    func observeConversations() -> AnyPublisher<[ChatConversation], Error> {
        guard let currentUserId = currentUser?.id else {
            return Fail(error: NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                .eraseToAnyPublisher()
        }
        
        return Future<[ChatConversation], Error> { promise in
            self.db.collection("conversations")
                .whereField("participants", arrayContains: currentUserId)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }
                    
                    Task {
                        do {
                            var conversations: [ChatConversation] = []
                            
                            for document in documents {
                                guard let matchId = document.data()["participants"] as? [String],
                                      let lastUpdated = (document.data()["lastUpdated"] as? Timestamp)?.dateValue() else {
                                    continue
                                }
                                
                                let otherUserId = matchId.first { $0 != currentUserId } ?? ""
                                let match = try await self.getUser(userId: otherUserId)
                                
                                let messagesSnapshot = try await document.reference.collection("messages").getDocuments()
                                let messages = messagesSnapshot.documents.compactMap { doc -> ChatMessage? in
                                    guard let data = try? doc.data(as: ChatMessage.self) else { return nil }
                                    return data
                                }
                                
                                let conversation = ChatConversation(
                                    id: document.documentID,
                                    match: match,
                                    messages: messages,
                                    lastUpdated: lastUpdated
                                )
                                
                                conversations.append(conversation)
                            }
                            
                            promise(.success(conversations))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func observeNewMatches() -> AnyPublisher<AppUser?, Error> {
        guard let currentUserId = currentUser?.id else {
            return Fail(error: NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
                .eraseToAnyPublisher()
        }
        
        return Future<AppUser?, Error> { promise in
            self.db.collection("matches")
                .whereField("users", arrayContains: currentUserId)
                .whereField("isNew", isEqualTo: true)
                .addSnapshotListener { snapshot, error in
                    if let error = error {
                        promise(.failure(error))
                        return
                    }
                    
                    guard let document = snapshot?.documents.first else {
                        promise(.success(nil))
                        return
                    }
                    
                    Task {
                        do {
                            guard let matchData = document.data()["users"] as? [String] else {
                                promise(.success(nil))
                                return
                            }
                            
                            let otherUserId = matchData.first { $0 != currentUserId } ?? ""
                            let match = try await self.getUser(userId: otherUserId)
                            
                            // Mark match as not new
                            try await document.reference.updateData(["isNew": false])
                            
                            promise(.success(match))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
        }
        .eraseToAnyPublisher()
    }
    
    func sendMessage(_ message: ChatMessage, in conversationId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            do {
                try self.db.collection("conversations")
                    .document(conversationId)
                    .collection("messages")
                    .document(message.id)
                    .setData(from: message) { error in
                        if let error = error {
                            promise(.failure(error))
                        } else {
                            // Update conversation's lastUpdated timestamp
                            self.db.collection("conversations")
                                .document(conversationId)
                                .updateData(["lastUpdated": FieldValue.serverTimestamp()]) { error in
                                    if let error = error {
                                        promise(.failure(error))
                                    } else {
                                        promise(.success(()))
                                    }
                                }
                        }
                    }
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func markMessageAsRead(_ messageId: String, in conversationId: String) -> AnyPublisher<Void, Error> {
        Future<Void, Error> { promise in
            self.db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .document(messageId)
                .updateData(["isRead": true]) { error in
                    if let error = error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
} 
