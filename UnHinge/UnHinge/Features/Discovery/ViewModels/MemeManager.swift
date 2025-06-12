import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseStorage

class MemeManager: ObservableObject {
    @Published var memes: [Meme] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private var db = Firestore.firestore()
    private var storage = Storage.storage()
    private var userId: String? { Auth.auth().currentUser?.uid }
    
    func fetchMemes() {
        isLoading = true
        errorMessage = nil
        guard let userId = userId else {
            self.errorMessage = "User not logged in."
            self.isLoading = false
            return
        }
        // Fetch liked/skipped meme IDs first
        db.collection("users").document(userId).getDocument { userDoc, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                return
            }
            let liked = userDoc?.data()? ["likedMemes"] as? [String] ?? []
            let skipped = userDoc?.data()? ["skippedMemes"] as? [String] ?? []
            let excludeIds = liked + skipped
            // Fetch memes not in excludeIds
            self.db.collection("memes").order(by: "uploadedAt", descending: true).getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    guard let documents = snapshot?.documents else {
                        self.errorMessage = "No memes found."
                        return
                    }
                    self.memes = documents.compactMap { doc in
                        let meme = try? doc.data(as: Meme.self)
                        if let meme = meme, !excludeIds.contains(meme.id) {
                            return meme
                        }
                        return nil
                    }
                }
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
                
                do {
                    try self.db.collection("memes").document(meme.id).setData(from: meme)
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
} 