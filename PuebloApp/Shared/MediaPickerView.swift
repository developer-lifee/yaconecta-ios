import SwiftUI
import PhotosUI
import UIKit

struct MediaPickerView: View {
    let title: String
    @Binding var mediaURLString: String
    @Binding var selectedImageData: Data?

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isShowingUrlInput = false
    @State private var isShowingCamera = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                // 1. Selector desde la galería de Fotos de iOS (PhotosPicker)
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("Galería de Fotos")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 12))
                }

                // 2. Tomar foto desde la cámara
                Button {
                    isShowingCamera = true
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Cámara")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundStyle(AppTheme.ink)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }

            HStack {
                Button(isShowingUrlInput ? "Ocultar opción de enlace" : "Ingresar enlace URL directamente") {
                    withAnimation { isShowingUrlInput.toggle() }
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)

                Spacer()

                if selectedImageData != nil || !mediaURLString.isEmpty {
                    Button("Quitar imagen", role: .destructive) {
                        selectedItem = nil
                        selectedImageData = nil
                        selectedImage = nil
                        mediaURLString = ""
                    }
                    .font(.caption.bold())
                }
            }

            if isShowingUrlInput {
                TextField("https://...", text: $mediaURLString)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
            }

            // Vista previa de la imagen seleccionada desde galería o cámara
            if let selectedImage {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vista previa (Galería/Cámara):")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else if let url = URL(string: mediaURLString), !mediaURLString.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Vista previa (Enlace):")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, minHeight: 80)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        selectedImageData = data
                        selectedImage = UIImage(data: data)
                        // Generar identificador de evidencia o data URL si es necesario
                        if let base64 = data.base64EncodedString().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                            mediaURLString = "data:image/jpeg;base64,\(base64.prefix(200))..."
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPickerView { capturedImage in
                selectedImage = capturedImage
                if let data = capturedImage.jpegData(compressionQuality: 0.8) {
                    selectedImageData = data
                    mediaURLString = "captured_photo_\(Date().timeIntervalSince1970).jpg"
                }
            }
        }
    }
}

struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onCapture: onCapture)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let dismiss: DismissAction
        let onCapture: (UIImage) -> Void

        init(dismiss: DismissAction, onCapture: @escaping (UIImage) -> Void) {
            self.dismiss = dismiss
            self.onCapture = onCapture
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
