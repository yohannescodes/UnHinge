import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class MemeSwipeViewModel: ObservableObject {
    @Published private(set) var currentMeme: Meme?
    @Published private(set) var currentMemeUploader: AppUser? = nil // Added uploader
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    private let firebaseService = FirebaseService.shared
    private var memeQueue: [Meme] = []
    private var currentIndex = 0
    private var currentTask: Task<Void, Never>?
    private var loadMoreThreshold = 5
    
    deinit {
        currentTask?.cancel()
    }
    
    func loadMemes() {
        guard !isLoading else { return }
        
        currentTask?.cancel()
        isLoading = true
        errorMessage = nil
        
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                guard let userId = Auth.auth().currentUser?.uid else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please sign in to continue"])
                }
                
                // Get user's liked and skipped memes
                let user = try await firebaseService.getUser(userId: userId)
                let likedMemeIds = user?.matches ?? []
                let skippedMemeIds = user?.memes?.compactMap { $0.id } ?? []
                
                // Query memes not in liked or skipped
                let db = Firestore.firestore()
                let query = db.collection("memes")
                    .whereField("uploadedBy", isNotEqualTo: userId)
                    .limit(to: 20)
                
                let snapshot = try await query.getDocuments()
                let newMemes = snapshot.documents.compactMap { document in
                    try? document.data(as: Meme.self)
                }.filter { meme in
                    !likedMemeIds.contains(meme.id) && !skippedMemeIds.contains(meme.id)
                }
                
                if !Task.isCancelled {
                    memeQueue.append(contentsOf: newMemes)
                    if self.currentMeme == nil && !memeQueue.isEmpty {
                        // currentMeme = memeQueue[0] // Replaced by method below
                        self.updateCurrentMemeAndFetchUploader(meme: memeQueue[0])
                    }
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
    
    func likeMeme() {
        guard let meme = currentMeme,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                // Call the new FirebaseService method
                try await self.firebaseService.recordSwipeAndCheckForMatch(meme: meme, currentUserId: userId)
                
                // Analytics (e.g., totalLikes on meme owner) are now expected to be handled by Firebase Functions
                // or a separate mechanism, so they are removed from here.
                // The user's own "matches" array (likedMemeIds) is also implicitly handled by the swipes collection.

                // Move to next meme
                self.moveToNextMeme()
                
                // Load more memes if needed
                if self.shouldLoadMore() {
                    self.loadMemes()
                }
            } catch {
                self.errorMessage = "Failed to process like: \(error.localizedDescription)"
            }
        }
    }
    
    func dislikeMeme() {
        guard let meme = currentMeme,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        // TODO: Implement dislike similar to like, by recording a "dislike" swipe.
        // This might involve a similar FirebaseService method like recordSwipe(type: "dislike", ...)
        // For now, this subtask focuses on the "like" and match logic.
        // The old dislike logic is kept temporarily but should be refactored.
        Task { [weak self] in
            guard let self = self else { return }
            do {
                // Old logic: directly update user's skipped memes.
                // This should ideally be replaced by writing to the 'swipes' collection with type: "dislike".
                // For this subtask, we are focusing on the like/match flow.
                // A full implementation would require `recordSwipe(type: "dislike")`
                 try await firebaseService.updateUser(userId: userId, data: [
                     "skippedMemes": FieldValue.arrayUnion([meme.id]) // Example: new field for skipped memes
                 ])
                
                // Analytics for skips would also move to backend functions.
                // async let updateMemeSkips = firebaseService.updateUser(userId: meme.uploadedBy, data: [
                // "analytics.totalSkips": FieldValue.increment(Int64(1))
                // ])
                // try await updateMemeSkips

                // Move to next meme
                self.moveToNextMeme()
                
                // Load more memes if needed
                if shouldLoadMore() {
                    loadMemes()
                }
            } catch {
                errorMessage = "Failed to skip meme: \(error.localizedDescription)"
            }
        }
    }
    
    private func moveToNextMeme() {
        currentIndex += 1
        if currentIndex < memeQueue.count {
            // currentMeme = memeQueue[currentIndex] // Replaced by method below
            updateCurrentMemeAndFetchUploader(meme: memeQueue[currentIndex])
        } else {
            // currentMeme = nil // Replaced by method below
            updateCurrentMemeAndFetchUploader(meme: nil)
            loadMemes() // Load more memes
        }
    }

    private func updateCurrentMemeAndFetchUploader(meme: Meme?) {
        self.currentMeme = meme
        self.currentMemeUploader = nil // Reset while fetching

        guard let meme = meme, !meme.uploadedBy.isEmpty else {
            // If meme is nil, currentMeme and currentMemeUploader are already nil (or set to nil above)
            return
        }

        Task { [weak self] in // Ensure it's managed within existing task structures
            guard let self = self else { return }
            do {
                let uploader = try await self.firebaseService.getUser(userId: meme.uploadedBy)
                await MainActor.run { // Ensure UI updates on main thread
                    // Check if the currentMeme is still the same one we fetched for, to avoid race conditions
                    if self.currentMeme?.id == meme.id {
                        self.currentMemeUploader = uploader
                    }
                }
            } catch {
                print("Error fetching uploader for meme \(meme.id): \(error)")
                await MainActor.run {
                   if self.currentMeme?.id == meme.id { // Check again in case currentMeme changed
                        self.currentMemeUploader = nil // Explicitly set to nil on error
                   }
                }
            }
        }
    }
    
    private func shouldLoadMore() -> Bool {
        guard !memeQueue.isEmpty else { return true }
        return memeQueue.count - currentIndex <= loadMoreThreshold
    }
} 
