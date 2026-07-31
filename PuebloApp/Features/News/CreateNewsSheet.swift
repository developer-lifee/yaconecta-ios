import SwiftUI

struct CreateNewsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @State private var draft = NewsDraft()
    @State private var isPublishing = false
    @State private var errorMessage: String?

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

                Section("Fuente") {
                    TextField("Ej. Lo vi personalmente, Bomberos…", text: $draft.sourceNote)
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
