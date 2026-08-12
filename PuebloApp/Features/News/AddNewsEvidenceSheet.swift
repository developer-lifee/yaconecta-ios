import SwiftUI

struct AddNewsEvidenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    let newsID: UUID

    @State private var imageURLText: String = ""
    @State private var selectedImageData: Data? = nil
    @State private var note: String = ""
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Material de Evidencia (Foto / Video)") {
                    MediaPickerView(
                        title: "Adjunta una fotografía o evidencia en video tomada en el lugar:",
                        mediaURLString: $imageURLText,
                        selectedImageData: $selectedImageData
                    )
                }

                Section("Detalle o Nota Aclaratoria (Opcional)") {
                    TextField("Ej. Foto tomada a las 5:15pm cerca al puente principal…", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                if let user = auth.currentUser {
                    Section("Autor") {
                        Label("Aportando como \(user.displayName)", systemImage: "person.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Añadir Evidencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publicar Evidencia") {
                        submitEvidence()
                    }
                    .font(.headline)
                    .disabled(imageURLText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func submitEvidence() {
        let cleanImage = imageURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanImage.isEmpty {
            errorMessage = "Por favor toma o selecciona una imagen/video de evidencia."
            return
        }

        let authorName = auth.currentUser?.displayName ?? "Vecino del Pueblo"
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = cleanNote.isEmpty ? nil : cleanNote

        let evidence = NewsEvidence(
            id: UUID(),
            author: authorName,
            imageURL: cleanImage,
            note: finalNote,
            createdAt: Date()
        )

        store.addNewsEvidence(newsID: newsID, evidence: evidence)
        dismiss()
    }
}
