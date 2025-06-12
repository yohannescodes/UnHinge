import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

@MainActor
final class MemeSwipeViewModel: ObservableObject {
    @Published private(set) var currentMeme: Meme?
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
                    if currentMeme == nil && !memeQueue.isEmpty {
                        currentMeme = memeQueue[0]
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
                async let updateUserMatches = firebaseService.updateUser(userId: userId, data: [
                    "matches": FieldValue.arrayUnion([meme.id])
                ])
                
                async let updateMemeLikes = firebaseService.updateUser(userId: meme.uploadedBy, data: [
                    "analytics.totalLikes": FieldValue.increment(Int64(1))
                ])
                
                // Execute both updates concurrently
                try await (updateUserMatches, updateMemeLikes)
                
                // Move to next meme
                moveToNextMeme()
                
                // Load more memes if needed
                if shouldLoadMore() {
                    loadMemes()
                }
            } catch {
                errorMessage = "Failed to like meme: \(error.localizedDescription)"
            }
        }
    }
    
    func dislikeMeme() {
        guard let meme = currentMeme,
              let userId = Auth.auth().currentUser?.uid else { return }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                async let updateUserSkips = firebaseService.updateUser(userId: userId, data: [
                    "memes": FieldValue.arrayUnion([meme.id])
                ])
                
                async let updateMemeSkips = firebaseService.updateUser(userId: meme.uploadedBy, data: [
                    "analytics.totalSkips": FieldValue.increment(Int64(1))
                ])
                
                // Execute both updates concurrently
                try await (updateUserSkips, updateMemeSkips)
                
                // Move to next meme
                moveToNextMeme()
                
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
            currentMeme = memeQueue[currentIndex]
        } else {
            currentMeme = nil
            loadMemes() // Load more memes
        }
    }
    
    private func shouldLoadMore() -> Bool {
        guard !memeQueue.isEmpty else { return true }
        return memeQueue.count - currentIndex <= loadMoreThreshold
    }
} 
