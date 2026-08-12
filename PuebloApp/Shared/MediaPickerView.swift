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
    @State private var cameraUnavailableAlert = false

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
                .buttonStyle(.plain)

                // 2. Tomar foto desde la cámara
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        isShowingCamera = true
                    } else {
                        cameraUnavailableAlert = true
                    }
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
                .buttonStyle(.plain)
            }

            HStack {
                Button(isShowingUrlInput ? "Ocultar opción de enlace" : "Ingresar enlace URL directamente") {
                    withAnimation { isShowingUrlInput.toggle() }
                }
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)

                Spacer()

                if selectedImageData != nil || !mediaURLString.isEmpty {
                    Button("Quitar imagen", role: .destructive) {
                        selectedItem = nil
                        selectedImageData = nil
                        selectedImage = nil
                        mediaURLString = ""
                    }
                    .font(.caption.bold())
                    .buttonStyle(.plain)
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
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedImageData = data
                        selectedImage = uiImage
                        if let base64String = compressAndEncodeImage(uiImage) {
                            mediaURLString = base64String
                        }
                    }
                }
            }
        }
        .alert("Cámara no disponible", isPresented: $cameraUnavailableAlert) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("La cámara no está disponible en este dispositivo. Por favor usa la opción Galería de Fotos.")
        }
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPickerView { capturedImage in
                selectedImage = capturedImage
                if let data = capturedImage.jpegData(compressionQuality: 0.8) {
                    selectedImageData = data
                    if let base64String = compressAndEncodeImage(capturedImage) {
                        mediaURLString = base64String
                    }
                }
            }
        }
    }
}

func compressAndEncodeImage(_ image: UIImage, maxDimension: CGFloat = 500) -> String? {
    let size = image.size
    guard size.width > 0, size.height > 0 else { return nil }
    let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
    let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let resized = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    if let data = (resized ?? image).jpegData(compressionQuality: 0.7) {
        return "data:image/jpeg;base64,\(data.base64EncodedString())"
    }
    return nil
}

struct CameraPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
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

struct SmartImageView: View {
    let urlString: String?
    var width: CGFloat? = nil
    var height: CGFloat
    var cornerRadius: CGFloat = 14
    var fallbackSymbol: String = "photo"
    var fallbackColor: Color = AppTheme.coral

    var body: some View {
        Group {
            if let urlString, !urlString.isEmpty {
                if urlString.hasPrefix("data:image"),
                   let commaPos = urlString.firstIndex(of: ","),
                   let data = Data(base64Encoded: String(urlString[urlString.index(after: commaPos)...])),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if let url = URL(string: urlString), urlString.hasPrefix("http") {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            placeholderView
                        }
                    }
                } else {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: width, height: height)
        .frame(maxWidth: width == nil ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholderView: some View {
        Image(systemName: fallbackSymbol)
            .font(.system(size: max(14, height * 0.38), weight: .semibold))
            .foregroundStyle(fallbackColor)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .background(fallbackColor.opacity(0.12), in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct MediaThumbnailView: View {
    let urlString: String
    let height: CGFloat

    var body: some View {
        SmartImageView(urlString: urlString, height: height)
    }
}
