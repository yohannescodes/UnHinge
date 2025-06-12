import SwiftUI
import PhotosUI
import Charts
import UIKit
import FirebaseAuth // For Auth.auth().signOut() in SettingsView

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAnalytics = false
    @State private var showingVerification = false
    
    @MainActor
    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    @MainActor
    init() {
        let defaultViewModel = ProfileViewModel()
        _viewModel = StateObject(wrappedValue: defaultViewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let profile = viewModel.currentProfile {
                        UserProfileView(profile: profile)
                        ProfileStatsView(user: profile.user)
                        ProfileActionsView(
                            showingEditProfile: $showingEditProfile,
                            showingAnalytics: $showingAnalytics,
                            showingSettings: $showingSettings,
                            showingDeleteConfirmation: $showingDeleteConfirmation,
                            showingAddMemeView: $viewModel.showingAddMemeView
                        )

                        if let user = viewModel.currentUser {
                            MemeDeckView(memes: user.memeDeck, onDelete: { memeId in
                                viewModel.removeMemeFromDeck(memeId: memeId)
                            })
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $viewModel.showingAddMemeView) {
                AddMemeToDeckView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingEditProfile) {
                if let user = viewModel.currentUser {
                    EditProfileView(user: user)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAnalytics) {
                if let user = viewModel.currentUser {
                    AnalyticsView(user: user)
                }
            }
            .sheet(isPresented: $showingVerification) {
                VerificationView()
            }
            .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteAccount()
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
            .overlay {
                if viewModel.isUploadingImage {
                    ProgressView("Uploading image...")
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 10)
                }
            }
        }
    }
}

// MARK: - Meme Deck View
private struct MemeDeckView: View {
    let memes: [Meme]
    let onDelete: (String) -> Void

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Text("My Meme Deck (\(memes.count))")
                .font(.title2)
                .bold()
                .padding(.horizontal)

            if memes.isEmpty {
                Text("Your meme deck is empty. Add some memes!")
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: columns, spacing: 8) {
                        ForEach(memes) { meme in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: meme.imageName)) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .overlay(ProgressView())
                                }
                                .frame(width: 150, height: 150)
                                .cornerRadius(8)
                                .clipped()

                                Button(action: {
                                    onDelete(meme.id)
                                }) {
                                    Image(systemName: "trash.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                        .padding(6)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 316)
            }
        }
        .padding(.vertical)
    }
}


// MARK: - Edit Profile View
struct EditProfileView: View {
    let user: User
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var bio: String
    @State private var interests: [String]
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var newInterest = ""
    @State private var socialLinks: User.SocialLinks
    
    init(user: User) {
        self.user = user
        _name = State(initialValue: user.name)
        _bio = State(initialValue: user.bio ?? "")
        _interests = State(initialValue: user.interests ?? [])
        _socialLinks = State(initialValue: user.socialLinks ?? User.SocialLinks())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Spacer()
                        Button(action: { showingImagePicker = true }) {
                            if let selectedImage = selectedImage {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else if let imageURL = user.profileImageURL {
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 100, height: 100)
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                Section("Basic Info") {
                    TextField("Name", text: $name)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Social Links") {
                    TextField("Instagram Username", text: Binding(
                        get: { socialLinks.instagram ?? "" },
                        set: { socialLinks.instagram = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Twitter Username", text: Binding(
                        get: { socialLinks.twitter ?? "" },
                        set: { socialLinks.twitter = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("TikTok Username", text: Binding(
                        get: { socialLinks.tiktok ?? "" },
                        set: { socialLinks.tiktok = $0.isEmpty ? nil : $0 }
                    ))
                    TextField("Spotify Username", text: Binding(
                        get: { socialLinks.spotify ?? "" },
                        set: { socialLinks.spotify = $0.isEmpty ? nil : $0 }
                    ))
                }
                
                Section("Interests") {
                    ForEach(interests, id: \.self) { interest in
                        Text(interest)
                    }
                    .onDelete { indexSet in
                        interests.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("Add interest", text: $newInterest)
                        Button("Add") {
                            if !newInterest.isEmpty {
                                interests.append(newInterest)
                                newInterest = ""
                            }
                        }
                        .disabled(newInterest.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateProfile(
                            name: name,
                            bio: bio.isEmpty ? nil : bio,
                            interests: interests,
                            profileImage: selectedImage,
                            socialLinks: socialLinks
                        )
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showMe = true
    @State private var minAge: Double = 18.0
    @State private var maxAge: Double = 99.0
    @State private var maxDistance = 50
    @State private var theme: AppTheme = .system
    @State private var language = "English"
    @State private var notifications = AppUser.NotificationPreferences(
        newMatches: true,
        messages: true,
        likes: true,
        profileViews: true,
        marketing: false
    )
    @State private var privacy = AppUser.PrivacySettings(
        showOnlineStatus: true,
        showLastActive: true,
        showDistance: true,
        showAge: true
    )
    
    var body: some View {
        NavigationView {
            Form {
                Section("Discovery Settings") {
                    Toggle("Show Me", isOn: $showMe)
                    
                    VStack(alignment: .leading) {
                        Text("Age Range: \(Int(minAge))-\(Int(maxAge))")
                        RangeSlider(value: $minAge, in: 18.0...99.0, step: 1.0)
                        RangeSlider(value: $maxAge, in: 18.0...99.0, step: 1.0)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Maximum Distance: \(maxDistance) miles")
//                        Slider(value: $maxDistance, in: 1...100, step: 1)
                    }
                }
                
                Section("Appearance") {
                    Picker("Theme", selection: $theme) {
                        Text("System").tag(AppTheme.system)
                        Text("Light").tag(AppTheme.light)
                        Text("Dark").tag(AppTheme.dark)
                    }
                    
                    Picker("Language", selection: $language) {
                        Text("English").tag("English")
                        Text("Spanish").tag("Spanish")
                        Text("French").tag("French")
                        Text("German").tag("German")
                    }
                }
                
                Section("Notifications") {
                    Toggle("New Matches", isOn: $notifications.newMatches)
                    Toggle("Messages", isOn: $notifications.messages)
                    Toggle("Likes", isOn: $notifications.likes)
                    Toggle("Profile Views", isOn: $notifications.profileViews)
                    Toggle("Marketing", isOn: $notifications.marketing)
                }
                
                Section("Privacy") {
                    Toggle("Show Online Status", isOn: $privacy.showOnlineStatus)
                    Toggle("Show Last Active", isOn: $privacy.showLastActive)
                    Toggle("Show Distance", isOn: $privacy.showDistance)
                    Toggle("Show Age", isOn: $privacy.showAge)
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        try? Auth.auth().signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        viewModel.updatePreferences(
                            theme: theme,
                            language: language,
                            notifications: notifications,
                            privacy: privacy
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    let analytics = user.analytics
                    VStack(spacing: 16) {
                        Text("Profile Stats")
                                .font(.headline)
                            
                            HStack(spacing: 20) {
                                StatView(title: "Total Swipes", value: String(analytics.totalSwipes))
                                StatView(title: "Memes Shared", value: String(analytics.memesShared))
                                StatView(title: "Matches", value: String(analytics.matches))
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        VStack(spacing: 16) {
                            Text("Match Stats")
                                .font(.headline)
                            
                            HStack(spacing: 20) {
                                StatView(title: "Messages Sent", value: String(analytics.messagesSent))
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                        
                        VStack(spacing: 16) {
                            Text("Activity Hours")
                                .font(.headline)
                            
                            Chart {
                                ForEach(Array(analytics.activeHours.sorted(by: { $0.key < $1.key })), id: \.key) { hour, count in
                                    BarMark(
                                        x: .value("Hour", "\(hour):00"),
                                        y: .value("Activity", count)
                                    )
                                }
                            }
                            .frame(height: 200)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 2)
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        }
    }


// MARK: - Verification View
struct VerificationView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Verify Your Profile")
                    .font(.title2)
                    .bold()
                
                Text("Take a selfie to verify your identity and get a verified badge on your profile.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                if viewModel.isVerifying {
                    ProgressView("Verifying...")
                } else {
                    Button(action: {
                        viewModel.requestVerification()
                    }) {
                        Text("Start Verification")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Profile Actions View
private struct ProfileActionsView: View {
    @Binding var showingEditProfile: Bool
    @Binding var showingAnalytics: Bool
    @Binding var showingSettings: Bool
    @Binding var showingDeleteConfirmation: Bool
    @Binding var showingAddMemeView: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button(action: { showingAddMemeView = true }) {
                Text("Add Meme to Deck")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
            }

            Button(action: { showingEditProfile = true }) {
                Text("Edit Profile")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Button(action: { showingAnalytics = true }) {
                Text("View Analytics")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
            
            Button(action: { showingSettings = true }) {
                Text("Settings")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
            }
            
            Button(action: { showingDeleteConfirmation = true }) {
                Text("Delete Account")
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

// MARK: - Range Slider
struct RangeSlider<V>: View where V: BinaryFloatingPoint, V.Stride: BinaryFloatingPoint {
    @Binding var value: V
    let range: ClosedRange<V>
    let step: V.Stride

    init(value: Binding<V>, in range: ClosedRange<V>, step: V.Stride) {
        self._value = value
        self.range = range
        self.step = step
    }

    var body: some View {
        Slider(
            value: self.$value,
            in: self.range,
            step: self.step,
            onEditingChanged: { _ in },
            minimumValueLabel: Text(String(describing: self.range.lowerBound)),
            maximumValueLabel: Text(String(describing: self.range.upperBound)),
            label: { EmptyView() }
        )
    }
}
