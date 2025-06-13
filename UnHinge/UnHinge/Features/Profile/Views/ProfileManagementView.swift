import SwiftUI
import PhotosUI
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

struct ProfileManagementView: View {
    @State private var firstName: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var gender: String = "Other"
    @State private var selectedMemes: [PhotosPickerItem] = []
    @State private var memeImages: [UIImage] = []
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    @State private var loadedMemes: [Meme] = []
    @State private var errorMessage: String? = nil
    
    let genders = ["Male", "Female", "Other"]
    
    var body: some View {
        Form {
            Section(header: Text("Basic Information")) {
                TextField("First Name", text: $firstName)
                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { gender in
                        Text(gender)
                    }
                }
            }
            
            Section(header: Text("Memes for Match Exploration")) {
                PhotosPicker(
                    selection: $selectedMemes,
                    maxSelectionCount: 5,
                    matching: .images,
                    photoLibrary: .shared()) {
                        Label("Select Memes", systemImage: "photo.on.rectangle")
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(memeImages, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(isSaving)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            loadProfile()
        }
        .onChange(of: selectedMemes) { newItems in
            loadMemes(from: newItems)
        }
        .alert("Profile Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) {}
        }
    }
    
    private func loadMemes(from items: [PhotosPickerItem]) {
        memeImages = []
        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    memeImages.append(image)
                }
            }
        }
    }
    
    private func loadProfile() {
        guard let user = Auth.auth().currentUser else { return }
        Task {
            do {
                let doc = try await Firestore.firestore().collection("users").document(user.uid).getDocument()
                guard let data = doc.data() else { return }
                let appUser = AppUser(dictionary: data)
                await MainActor.run {
                    self.firstName = appUser?.name ?? ""
                    self.gender = appUser?.gender ?? "Other"
                    self.dateOfBirth = appUser?.dateOfBirth ?? Date()
                    self.loadedMemes = appUser?.memeDeck ?? []
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load profile."
                }
            }
        }
    }
    
    private func saveProfile() {
        // Validation
        guard !firstName.isEmpty else { return }
        guard Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0 >= 18 else { return }
        guard !gender.isEmpty else { return }
        guard let user = Auth.auth().currentUser else { return }
        isSaving = true
        Task {
            do {
                var memeURLs: [String] = []
                for image in memeImages {
                    let memeId = UUID().uuidString
                    let storageRef = Storage.storage().reference().child("memes/\(memeId).jpg")
                    guard let imageData = image.jpegData(compressionQuality: 0.7) else { continue }
                    _ = try await storageRef.putDataAsync(imageData)
                    let url = try await storageRef.downloadURL()
                    memeURLs.append(url.absoluteString)
                }
                // Append new memes to loadedMemes
                var updatedMemes = loadedMemes
                updatedMemes.append(contentsOf: memeURLs.map { Meme(id: UUID().uuidString, imageName: $0, tags: [], uploadedBy: user.uid, uploadedAt: Date(), likes: 0, views: 0) })
                // Only update changed fields
                let updateData: [String: Any] = [
                    "name": firstName,
                    "gender": gender,
                    "dateOfBirth": Timestamp(date: dateOfBirth),
                    "memeDeck": updatedMemes.map { $0.dictionary }
                ]
                try await Firestore.firestore().collection("users").document(user.uid).updateData(updateData)
                isSaving = false
                showSaveSuccess = true
                // Update loadedMemes so UI stays in sync
                await MainActor.run {
                    self.loadedMemes = updatedMemes
                    self.memeImages = []
                }
            } catch {
                isSaving = false
                await MainActor.run {
                    self.errorMessage = "Failed to save profile."
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        ProfileManagementView()
    }
} 

