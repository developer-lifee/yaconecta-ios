import SwiftUI

struct CreateNewsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @State private var draft = NewsDraft()
    @State private var isPublishing = false
    @State private var errorMessage: String?
    @State private var imageUrlInput = ""
    @State private var selectedImageData: Data? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Información de la Noticia") {
                    TextField("Título claro y concreto", text: $draft.title)
                    Picker("Categoría", selection: $draft.category) {
                        ForEach(NewsCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbol).tag(category)
                        }
                    }
                    Picker("Prioridad", selection: $draft.urgency) {
                        ForEach(NewsUrgency.allCases) { urgency in
                            Text(urgency.rawValue).tag(urgency)
                        }
                    }
                    TextField("¿Qué ocurrió? Incluye hora y contexto", text: $draft.body, axis: .vertical)
                        .lineLimit(4...8)
                    TextField("Lugar exacto o sector (ej. Parque Principal, Vía Cubarral)", text: $draft.location)
                }

                Section("Alcance de la Noticia") {
                    Picker("Alcance Geográfico", selection: $draft.isRegional) {
                        Label("📍 Solo \(store.selectedTown?.name ?? "este pueblo")", systemImage: "mappin.circle.fill").tag(false)
                        Label("🌐 Regional (Cubarral - El Dorado - Guamal)", systemImage: "globe.americas.fill").tag(true)
                    }
                    .pickerStyle(.menu)

                    if draft.isRegional {
                        Text("Esta noticia aparecerá en los feeds de San Luis de Cubarral, El Dorado y municipios vecinos.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Evidencia Fotográfica / Videográfica") {
                    MediaPickerView(
                        title: "Adjunta fotos o videos de la evidencia desde tu cámara o galería del iPhone:",
                        mediaURLString: $imageUrlInput,
                        selectedImageData: $selectedImageData
                    )
                    .onChange(of: imageUrlInput) { _, newValue in
                        draft.imageURL = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }

                Section("Fuente (opcional)") {
                    TextField("Ej. Lo vi personalmente, Bomberos, Vecino del sector…", text: $draft.sourceNote)
                }

                if draft.category == .mourning {
                    Section {
                        Label(
                            "Por respeto, publica nombres, fotografías o detalles personales solamente con autorización de la familia.",
                            systemImage: "heart.text.square.fill"
                        )
                        .font(.footnote)
                        .foregroundStyle(.purple)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote.bold())
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Informar al pueblo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publicar") {
                        validateAndPublish()
                    }
                    .fontWeight(.bold)
                    .disabled(isPublishing)
                    .accessibilityIdentifier("publish-news-button")
                }
            }
        }
    }

    private func validateAndPublish() {
        errorMessage = nil
        let titleClean = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyClean = draft.body.trimmingCharacters(in: .whitespacesAndNewlines)
        let locationClean = draft.location.trimmingCharacters(in: .whitespacesAndNewlines)

        if titleClean.isEmpty {
            errorMessage = "Por favor ingresa un título para la noticia."
            return
        }
        if titleClean.count < 3 {
            errorMessage = "El título debe tener al menos 3 caracteres."
            return
        }
        if bodyClean.isEmpty {
            errorMessage = "Por favor escribe los detalles de lo que ocurrió."
            return
        }
        if bodyClean.count < 6 {
            errorMessage = "La descripción debe tener al menos 6 caracteres."
            return
        }
        if locationClean.isEmpty {
            errorMessage = "Por favor indica el lugar o sector de la noticia."
            return
        }

        Task { await publish() }
    }

    private func publish() async {
        guard let townID = store.selectedTown?.id else {
            errorMessage = "Por favor selecciona un pueblo primero."
            return
        }
        guard let user = auth.currentUser else {
            errorMessage = "Debes iniciar sesión para publicar noticias."
            return
        }
        isPublishing = true
        defer { isPublishing = false }
        do {
            let item = try await SupabaseNewsService(client: auth.client)
                .publish(draft, townID: townID, user: user)
            store.upsertNews(item)
            dismiss()
        } catch {
            errorMessage = "No pudimos publicar: \(error.localizedDescription)"
        }
    }
}
