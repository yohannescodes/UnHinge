import SwiftUI
import PhotosUI // For PHPickerViewController

struct AddMemeToDeckView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel // Assuming ProfileViewModel is passed

    @State private var selectedImage: UIImage?
    @State private var tagsString: String = ""
    @State private var showImagePicker: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Meme")
                    .font(.headline)

                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                        .onTapGesture {
                            showImagePicker = true
                        }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(10)
                        .overlay(
                            Text("Tap to select image")
                                .foregroundColor(.gray)
                        )
                        .onTapGesture {
                            showImagePicker = true
                        }
                }

                TextField("Enter tags, separated by commas", text: $tagsString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                Button(action: {
                    guard let image = selectedImage else {
                        viewModel.errorMessage = "Please select an image."
                        return
                    }
                    Task {
                        await viewModel.addMemeToDeck(image: image, tagsInput: tagsString)
                        if viewModel.errorMessage == nil { // Assuming error message is nil on success
                            dismiss()
                        }
                    }
                }) {
                    Text("Upload Meme")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(viewModel.isLoading || selectedImage == nil)

                Spacer()
            }
            .padding()
            .navigationTitle("Add Meme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                // Assuming ImagePicker is a struct that takes a binding to UIImage?
                ImagePicker(image: $selectedImage)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Uploading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
            }
        }
    }
}

// Preview (Optional - requires mock ProfileViewModel)
// struct AddMemeToDeckView_Previews: PreviewProvider {
//     static var previews: some View {
//         // You'd need a way to mock or instantiate ProfileViewModel for the preview
//         // For example:
//         // AddMemeToDeckView(viewModel: MockProfileViewModel())
//         Text("Preview requires ProfileViewModel setup")
//     }
// }
// MockProfileViewModel for preview purposes (if needed)
// class MockProfileViewModel: ProfileViewModel {
//     override init(currentUser: AppUser? = nil) {
//         super.init(currentUser: currentUser)
//         // Initialize any properties needed for the preview
//     }
//     // Override methods if they are called by the view during preview
// }

// Placeholder for ImagePicker - Assuming this exists elsewhere
// and is compatible with the .sheet presentation.
// If ImagePicker is not defined, this will cause a compile error.
// struct ImagePicker: UIViewControllerRepresentable {
//     @Binding var image: UIImage?
//     @Environment(\.presentationMode) var presentationMode
//
//     func makeUIViewController(context: Context) -> PHPickerViewController {
//         var config = PHPickerConfiguration()
//         config.filter = .images
//         config.selectionLimit = 1
//         let picker = PHPickerViewController(configuration: config)
//         picker.delegate = context.coordinator
//         return picker
//     }
//
//     func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
//
//     func makeCoordinator() -> Coordinator {
//         Coordinator(self)
//     }
//
//     class Coordinator: NSObject, PHPickerViewControllerDelegate {
//         let parent: ImagePicker
//
//         init(_ parent: ImagePicker) {
//             self.parent = parent
//         }
//
//         func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
//             parent.presentationMode.wrappedValue.dismiss()
//             guard let provider = results.first?.itemProvider else { return }
//
//             if provider.canLoadObject(ofClass: UIImage.self) {
//                 provider.loadObject(ofClass: UIImage.self) { image, _ in
//                     self.parent.image = image as? UIImage
//                 }
//             }
//         }
//     }
// }
