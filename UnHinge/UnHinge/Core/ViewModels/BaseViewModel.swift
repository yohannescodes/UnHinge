import Foundation
import Combine

@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var cancellables = Set<AnyCancellable>()
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func startLoading() {
        isLoading = true
        clearError()
    }
    
    func stopLoading() {
        isLoading = false
    }
    
    func performTask(_ task: @escaping () async throws -> Void) {
        startLoading()
        
        Task {
            do {
                try await task()
            } catch {
                handleError(error)
            }
            stopLoading()
        }
    }
} 