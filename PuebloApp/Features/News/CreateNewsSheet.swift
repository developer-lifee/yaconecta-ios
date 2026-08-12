import SwiftUI

struct CreateNewsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @State private var draft = NewsDraft()
    @State private var isPublishing = false
    @State private var errorMessage: String?
    @State private var imageUrlInput = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
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
                        .lineLimit(5...9)
                    TextField("Lugar exacto o sector", text: $draft.location)
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
                    TextField("URL de foto o evidencia (opcional)", text: $imageUrlInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .onChange(of: imageUrlInput) { _, newValue in
                            draft.imageURL = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                        }

                    HStack(spacing: 12) {
                        Button {
                            // URL de muestra de evidencia para demostración rápida
                            imageUrlInput = "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800"
                        } label: {
                            Label("Adjuntar foto de muestra", systemImage: "photo.badge.plus")
                                .font(.caption.bold())
                        }
                        .buttonStyle(.bordered)

                        if imageUrlInput.isEmpty == false {
                            Button("Quitar", role: .destructive) {
                                imageUrlInput = ""
                            }
                            .font(.caption)
                        }
                    }

                    if let urlString = draft.imageURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 160)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            case .failure:
                                Label("No se pudo cargar la imagen", systemImage: "photo.badge.exclamationmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            default:
                                ProgressView()
                            }
                        }
                    }
                }

                Section("Fuente") {
                    TextField("Ej. Lo vi personalmente, Bomberos, Vecino del sector…", text: $draft.sourceNote)
                    Toggle("Confirmo que comparto información de buena fe", isOn: $draft.acceptsResponsibility)
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

                Section {
                    Label(
                        "La publicación aparecerá como “Sin verificar” hasta recibir confirmaciones o revisión de un moderador.",
                        systemImage: "checkmark.shield.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(AppTheme.moss)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
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
                        Task { await publish() }
                    }
                    .fontWeight(.bold)
                    .disabled(!draft.isValid || !auth.isSignedIn || isPublishing)
                    .accessibilityIdentifier("publish-news-button")
                }
            }
        }
    }

    private func publish() async {
        guard let townID = store.selectedTown?.id, let user = auth.currentUser else { return }
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
