import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class TalkingStageViewModel: ObservableObject {
    @Published private(set) var conversations: [ChatConversation] = []
    @Published private(set) var newMatch: AppUser?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        firebaseService.observeConversations()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] conversations in
                self?.conversations = conversations
            }
            .store(in: &cancellables)
        
        firebaseService.observeNewMatches()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] match in
                self?.newMatch = match
            }
            .store(in: &cancellables)
    }
    
    func sendMessage(_ text: String, in conversation: ChatConversation) {
        guard let currentUser = firebaseService.currentUser else { return }
        
        let message = ChatMessage(
            text: text,
            senderId: currentUser.id
        )
        
        firebaseService.sendMessage(message, in: conversation.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    func markAsRead(_ message: ChatMessage, in conversation: ChatConversation) {
        firebaseService.markMessageAsRead(message.id, in: conversation.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
} 