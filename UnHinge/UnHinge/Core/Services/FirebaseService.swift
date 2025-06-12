import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseStorage
import Combine

class FirebaseService {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {}
    
    // MARK: - User Operations
    
    func getUser(userId: String) async throws -> User? {
        let document = try await db.collection("users").document(userId).getDocument()
        return try document.data(as: User.self)
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
    
    // MARK: - Authentication Operations
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
    }
} 