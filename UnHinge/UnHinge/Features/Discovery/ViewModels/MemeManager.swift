import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import UIKit
import Combine

@MainActor
final class MemeManager: ObservableObject {
    @Published var memes: [Meme] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    private var userId: String? { Auth.auth().currentUser?.uid }
    private var currentTask: Task<Void, Never>?
    
    deinit {
        currentTask?.cancel()
    }
    
    func fetchMemes() {
        currentTask?.cancel()
        isLoading = true
        errorMessage = nil
        
        currentTask = Task {
            do {
                guard let userId = userId else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
                }
                
                // Fetch liked/skipped meme IDs first
                let userDoc = try await db.collection("users").document(userId).getDocument()
                let liked = userDoc.data()?["likedMemes"] as? [String] ?? []
                let skipped = userDoc.data()?["skippedMemes"] as? [String] ?? []
                let excludeIds = liked + skipped
                
                // Fetch memes not in liked or skipped
                let query = db.collection("memes")
                    .whereField("uploadedBy", isNotEqualTo: userId)
                    .limit(to: 20)
                
                let snapshot = try await query.getDocuments()
                memes = snapshot.documents.compactMap { document in
                    let data = document.data()
                    let id = document.documentID
                    guard let imageUrl = data["imageUrl"] as? String,
                          let caption = data["caption"] as? String,
                          let uploadedBy = data["uploadedBy"] as? String,
                          let uploadedAtTimestamp = data["uploadedAt"] as? Timestamp,
                          let likes = data["likes"] as? Int,
                          let skips = data["skips"] as? Int else {
                        return nil
                    }
                    return Meme(
                        id: id,
                        imageUrl: imageUrl,
                        caption: caption,
                        uploadedBy: uploadedBy,
                        uploadedAt: uploadedAtTimestamp.dateValue(),
                        likes: likes,
                        skips: skips
                    )
                }.filter { meme in
                    !excludeIds.contains(meme.id)
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
            
            if !Task.isCancelled {
                isLoading = false
            }
        }
    }
    
    func likeMeme(memeId: String) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).updateData([
            "likedMemes": FieldValue.arrayUnion([memeId])
        ])
    }
    
    func skipMeme(memeId: String) {
        guard let userId = userId else { return }
        db.collection("users").document(userId).updateData([
            "skippedMemes": FieldValue.arrayUnion([memeId])
        ])
    }
    
    func uploadMeme(image: UIImage, caption: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userId = userId else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])))
            return
        }
        
        let storageRef = storage.reference().child("memes/\(UUID().uuidString).jpg")
        
        // Upload image to Firebase Storage
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                // Create meme document in Firestore
                let meme = Meme(
                    id: UUID().uuidString,
                    imageUrl: downloadURL.absoluteString,
                    caption: caption,
                    uploadedBy: userId,
                    uploadedAt: Date(),
                    likes: 0,
                    skips: 0
                )
                
                let memeData: [String: Any] = [
                    "id": meme.id,
                    "imageUrl": meme.imageUrl,
                    "caption": meme.caption,
                    "uploadedBy": meme.uploadedBy,
                    "uploadedAt": Timestamp(date: meme.uploadedAt),
                    "likes": meme.likes,
                    "skips": meme.skips
                ]
                self.db.collection("memes").document(meme.id).setData(memeData) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
} 
