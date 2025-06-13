import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    // Add presentationMode to dismiss the picker.
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared()) // Ensure access to shared library
        config.filter = .images
        config.selectionLimit = 1
        // Optional: config.preferredAssetRepresentationMode = .current (to respect HEIC/JPEG choices)
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate, UINavigationControllerDelegate { // Added UINavigationControllerDelegate
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Dismiss the picker first.
            // Using parent.presentationMode.wrappedValue.dismiss() might be more SwiftUI idiomatic
            // if this coordinator was directly part of a View's state.
            // Since PHPickerViewController is a UIViewController, its own dismiss is fine.
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else {
                self.parent.image = nil // No image selected or provider unavailable
                return
            }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let error = error {
                        print("Error loading image: \(error.localizedDescription)")
                        self.parent.image = nil
                        return
                    }
                    // Ensure update is on the main thread if necessary, though @Binding should handle it.
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            } else {
                print("Cannot load UIImage from provider.")
                self.parent.image = nil
            }
        }
    }
}
