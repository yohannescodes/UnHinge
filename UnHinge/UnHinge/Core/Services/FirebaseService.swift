import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseMessaging
import Combine
import UIKit
import AuthenticationServices // Import for Apple Sign-In
import CryptoKit // Import for SHA256 hashing

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
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        // Generate nonce for validation
        let rawNonce = randomNonceString()
        request.nonce = sha256(rawNonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        // For simplicity in this context, we're assuming the view controller handling
        // this would be passed or accessed globally. In a real app, this needs careful handling.
        // This is a placeholder and might need adjustment based on actual app architecture.
        // For now, we'll assume a way to get the top view controller.
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentationAnchor = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            throw NSError(domain: "FirebaseServiceError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not get presentation anchor."])
        }
        controller.presentationContextProvider = PresentationContextProvider(presentationAnchor: presentationAnchor)

        return try await withCheckedThrowingContinuation { continuation in
            let delegate = AppleSignInAuthDelegate(
                nonce: rawNonce,
                onCompletion: { credential, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let appleIDCredential = credential as? ASAuthorizationAppleIDCredential else {
                        continuation.resume(throwing: NSError(domain: "FirebaseServiceError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple ID Credential"]))
                        return
                    }

                    guard let appleIDToken = appleIDCredential.identityToken else {
                        continuation.resume(throwing: NSError(domain: "FirebaseServiceError", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing identity token."]))
                        return
                    }

                    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                        continuation.resume(throwing: NSError(domain: "FirebaseServiceError", code: -4, userInfo: [NSLocalizedDescriptionKey: "Could not stringify identity token."]))
                        return
                    }

                    let firebaseCredential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                                         rawNonce: rawNonce,
                                                                         fullName: appleIDCredential.fullName)

                    Auth.auth().signIn(with: firebaseCredential) { authResult, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let authResult = authResult {
                            continuation.resume(returning: authResult)
                        } else {
                            // Should not happen
                            continuation.resume(throwing: NSError(domain: "FirebaseServiceError", code: -5, userInfo: [NSLocalizedDescriptionKey: "Unknown error during Firebase sign-in."]))
                        }
                    }
                }
            )
            controller.delegate = delegate
            controller.performRequests()
            // Keep the delegate alive until the continuation is resumed
            // This is a simplified way to handle the delegate's lifecycle for this example.
            // In a real app, you might manage this differently, e.g., by making the delegate a property of the class.
            objc_setAssociatedObject(controller, "appleSignInDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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

    // Helper for Apple Sign In Nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    // MARK: - Matching Operations

    func recordSwipeAndCheckForMatch(meme: Meme, currentUserId: String) async throws {
        let memeOwnerId = meme.uploadedBy

        // 1. Atomically record the swipe
        let swipeData: [String: Any] = [
            "swiperId": currentUserId,
            "likedMemeId": meme.id, // ID of the meme that was liked
            "memeOwnerId": memeOwnerId, // Owner of the liked meme
            "type": "like",
            "timestamp": FieldValue.serverTimestamp()
        ]
        try await db.collection("swipes").addDocument(data: swipeData)

        // 2. Check for a reciprocal like
        // User A (currentUserId) liked User B's (memeOwnerId) meme.
        // We need to check if User B (memeOwnerId) liked any of User A's (currentUserId) memes.
        let reciprocalSwipeQuery = db.collection("swipes")
            .whereField("swiperId", isEqualTo: memeOwnerId) // User B is the swiper
            .whereField("memeOwnerId", isEqualTo: currentUserId) // User A is the owner of the meme User B swiped on
            .whereField("type", isEqualTo: "like")
            // .limit(to: 1) // Optimization: we only need to know if at least one such swipe exists

        let querySnapshot = try await reciprocalSwipeQuery.getDocuments()

        if !querySnapshot.documents.isEmpty {
            // Reciprocal like exists, a match is formed!
            // 3. Create match document
            // Ensure consistent match ID to avoid duplicates if possible from client side
            let userIds = [currentUserId, memeOwnerId].sorted()
            let matchId = userIds.joined(separator: "_")

            let matchData: [String: Any] = [
                "users": [currentUserId, memeOwnerId], // Store both user IDs in the match
                "createdAt": FieldValue.serverTimestamp(),
                "isNew": true, // Flag for new match observation
                // Optionally, could include IDs of the memes that formed the match, if useful
                // "triggeringMemeIds": [meme.id, querySnapshot.documents.first?.data()["likedMemeId"]]
            ]

            // Use setData to ensure the document is created with the specific ID.
            // If both users create this simultaneously, one will win. `isNew: true` might be overwritten.
            // This is a known limitation for client-side match creation.
            try await db.collection("matches").document(matchId).setData(matchData)
        }
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
        print("Adding meme to user's memeDeck with arrayUnion...")
        try await db.collection("users").document(userId).updateData([
            "memeDeck": FieldValue.arrayUnion([try Firestore.Encoder().encode(meme)])
        ])
        print("Successfully added meme to memeDeck.")
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
            print("Failed to prepare image data for upload.")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare image"])
        }
        print("Image size: \(imageData.count) bytes")
        let memeId = UUID().uuidString
        let imageRef = storage.reference().child("memes/\(memeId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        print("Uploading image to Firebase Storage at memes/\(memeId).jpg ...")
        _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        print("Image uploaded. Getting download URL...")
        let url = try await imageRef.downloadURL()
        print("Download URL obtained: \(url.absoluteString)")
        let meme = Meme(
            id: memeId,
            imageName: url.absoluteString,
            tags: tags,
            uploadedBy: userId,
            uploadedAt: Date(),
            likes: 0,
            views: 0
        )
        print("Saving meme to memes collection in Firestore...")
        try await db.collection("memes").document(memeId).setData(from: meme)
        print("Meme saved to memes collection.")
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
                        promise(.success([])) // No documents, return empty array
                        return
                    }
                    
                    Task { // Launch a Task for the asynchronous processing
                        var fetchedConversations: [ChatConversation] = []
                        for document in documents {
                            guard let participants = document.data()["participants"] as? [String],
                                  let lastUpdated = (document.data()["lastUpdated"] as? Timestamp)?.dateValue() else {
                                print("Skipping conversation \(document.documentID) due to missing fields.")
                                continue
                            }
                            
                            let otherUserId = participants.first { $0 != currentUserId } ?? ""
                            if otherUserId.isEmpty {
                                print("Skipping conversation \(document.documentID) due to missing otherUserId.")
                                continue
                            }

                            do {
                                guard let matchedUser = try await self.getUser(userId: otherUserId) else {
                                    print("Could not fetch user for \(otherUserId) in conversation \(document.documentID). Skipping.")
                                    continue
                                }
                                
                                let messagesSnapshot = try await document.reference.collection("messages").getDocuments()
                                let messages = messagesSnapshot.documents.compactMap { msgDoc -> ChatMessage? in
                                    try? msgDoc.data(as: ChatMessage.self)
                                }
                                
                                fetchedConversations.append(ChatConversation(
                                    id: document.documentID,
                                    match: matchedUser,
                                    messages: messages,
                                    lastUpdated: lastUpdated
                                ))
                            } catch {
                                print("Error processing conversation \(document.documentID): \(error). Skipping.")
                                // Optionally, if one conversation processing fails, you might want to fail the whole promise
                                // promise(.failure(error))
                                // return
                                // Or, just skip this one and continue with others.
                            }
                        }
                        promise(.success(fetchedConversations))
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
                            // Ensure 'match' is non-nil before calling promise.success
                            if let validMatch = match {
                                promise(.success(validMatch))
                            } else {
                                // If match became nil after fetching (e.g. user deleted during fetch)
                                promise(.success(nil))
                            }
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
    // The duplicate markMessageAsRead at the end of the file will be removed by find/replace.
    // If it's the one around line 378 (original estimate), ensure the one at ~527 is removed.
    // The current file content shows the first one at ~380, the second (duplicate) at ~530.
}


// Helper extension for asyncCompactMap if not available (iOS < 15 or custom)
// For this exercise, assume it's available or the structure above is adapted.
// If iOS 13/14 support is needed without custom extensions:
// Task {
//    var tempConversations = [ChatConversation]()
//    for document in documents {
//        // ... perform async getUser and getMessages ...
//        // if successful, create ChatConversation and append to tempConversations
//    }
//    promise(.success(tempConversations))
// }
// The provided diff uses asyncCompactMap directly for brevity.

// PresentationContextProvider for ASAuthorizationController
private class PresentationContextProvider: NSObject, ASAuthorizationControllerPresentationContextProviding {
    let presentationAnchor: ASPresentationAnchor
    init(presentationAnchor: ASPresentationAnchor) {
        self.presentationAnchor = presentationAnchor
        super.init()
    }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchor
    }
}

// Delegate for handling Apple Sign-In authorization
private class AppleSignInAuthDelegate: NSObject, ASAuthorizationControllerDelegate {
    private let nonce: String
    private let onCompletion: (ASAuthorizationCredential?, Error?) -> Void

    init(nonce: String, onCompletion: @escaping (ASAuthorizationCredential?, Error?) -> Void) {
        self.nonce = nonce
        self.onCompletion = onCompletion
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion(authorization.credential, nil)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onCompletion(nil, error)
    }
}
