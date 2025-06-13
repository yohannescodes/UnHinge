import SwiftUI

struct MemePreferencesOnboardingView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel // Assuming it's passed as an EnvironmentObject
    // Alternative: @ObservedObject var authViewModel: AuthenticationViewModel
    // Alternative: var onComplete: ([String]) -> Void

    @State private var selectedPreferences: Set<String> = []

    // Predefined list of meme vibe tags
    private let memeVibeTags: [String] = [
        "Dark Humor", "Wholesome", "Absurd", "Relatable",
        "Gaming", "Animals", "Current Events", "Niche",
        "Science & Tech", "History Buff", "Pun Life", "Surreal"
    ]

    // Layout for the tags
    private var gridItemLayout: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()

            Text("What kind of memes do you vibe with?")
                .font(.title)
                .fontWeight(.bold)
                .padding(.horizontal)

            Text("Select a few to get started. This will help us tune your feed!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: gridItemLayout, spacing: 12) {
                    ForEach(memeVibeTags, id: \.self) { tag in
                        Button(action: {
                            togglePreference(tag)
                        }) {
                            Text(tag)
                                .font(.caption)
                                .fontWeight(selectedPreferences.contains(tag) ? .bold : .regular)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedPreferences.contains(tag) ? .white : .primary)
                                .background(selectedPreferences.contains(tag) ? Color.blue : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }

            if let errorMessage = authViewModel.errorMessage { // Assuming authViewModel has an error message property
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }

            Button(action: {
                Task {
                    // Convert Set to Array for saving
                    await authViewModel.saveMemePreferences(preferences: Array(selectedPreferences))
                    // The ViewModel should set showMemePreferencesOnboarding to false on success
                }
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedPreferences.isEmpty ? Color.gray.opacity(0.5) : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(selectedPreferences.isEmpty || authViewModel.isLoading) // Disable if no selection or if loading
            .padding()

            Spacer()
        }
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .overlay {
            if authViewModel.isLoading {
                ProgressView("Saving...")
                .padding()
                .background(.thinMaterial)
                .cornerRadius(10)
            }
        }
    }

    private func togglePreference(_ tag: String) {
        if selectedPreferences.contains(tag) {
            selectedPreferences.remove(tag)
        } else {
            selectedPreferences.insert(tag)
        }
    }
}

struct MemePreferencesOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock AuthenticationViewModel for previewing
        let mockAuthViewModel = AuthenticationViewModel()
        // You might want to set some state on the mock VM if needed for different previews

        MemePreferencesOnboardingView()
            .environmentObject(mockAuthViewModel)
    }
}
