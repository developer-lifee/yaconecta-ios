import SwiftUI

struct NewsDetailView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    let newsID: CommunityNews.ID
    @State private var showReportConfirmation = false
    @State private var confirmationError: String?
    @State private var showAddEvidenceSheet = false

    var body: some View {
        Group {
            if let news = store.news.first(where: { $0.id == newsID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Label(news.category.rawValue, systemImage: news.category.symbol)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.coral)
                            Spacer()
                            if news.isRegional {
                                Label("Alcance Regional", systemImage: "globe.americas.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                            }
                            Text(news.createdAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(news.title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(AppTheme.ink)

                        VerificationBadge(status: news.verification, confirmations: news.confirmationCount)

                        if let imageURLString = news.imageURL, !imageURLString.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Foto Principal (Autor):")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                MediaThumbnailView(urlString: imageURLString, height: 220)
                            }
                        }

                        Text(news.body)
                            .font(.body)
                            .lineSpacing(5)

                        Divider()

                        // Sección de Evidencias Aportadas por Vecinos
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Evidencias de Vecinos (\(news.evidences.count))")
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.ink)
                                    Text("Pruebas o fotos aportadas por la comunidad")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    showAddEvidenceSheet = true
                                } label: {
                                    Label("Añadir Evidencia", systemImage: "camera.fill")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .foregroundStyle(.white)
                                        .background(AppTheme.coral, in: Capsule())
                                }
                            }

                            if news.evidences.isEmpty {
                                Text("Aún no hay evidencias adicionales aportadas por vecinos. Si estás cerca, puedes aportar una foto o video como prueba.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(12)
                                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            } else {
                                ForEach(news.evidences) { item in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Label(item.author, systemImage: "person.circle.fill")
                                                .font(.caption.bold())
                                                .foregroundStyle(AppTheme.ink)
                                            Spacer()
                                            Text(item.createdAt, style: .relative)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        SmartImageView(urlString: item.imageURL, height: 180, cornerRadius: 12)
                                        if let note = item.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }

                        Divider()

                        Label(news.location, systemImage: "mappin.and.ellipse")
                        Label("Publicado por \(news.author)", systemImage: "person.crop.circle")
                        if let source = news.sourceNote {
                            Label(source, systemImage: "link")
                        }
                        Divider()

                        // Solo mostrar botón de confirmación si no eres el autor de la noticia
                        if isNotAuthor(news: news) {
                            Button {
                                Task { await confirm(news: news) }
                            } label: {
                                Label(
                                    news.didConfirm ? "Ya confirmaste este reporte" : "Yo también puedo confirmar esto",
                                    systemImage: news.didConfirm ? "checkmark.circle.fill" : "person.badge.shield.checkmark.fill"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(news.didConfirm || !auth.isSignedIn)

                            if !auth.isSignedIn {
                                Text("Inicia sesión para confirmar reportes.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }

                        if let confirmationError {
                            Text(confirmationError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }

                        Button("Reportar información incorrecta", role: .destructive) {
                            showReportConfirmation = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(20)
                }
                .alert("Reporte recibido", isPresented: $showReportConfirmation) {
                    Button("Entendido", role: .cancel) {}
                } message: {
                    Text("Un moderador local revisará esta publicación.")
                }
                .sheet(isPresented: $showAddEvidenceSheet) {
                    AddNewsEvidenceSheet(newsID: news.id)
                }
            } else {
                ContentUnavailableView("Noticia no disponible", systemImage: "newspaper")
            }
        }
        .navigationTitle("Noticia")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isNotAuthor(news: CommunityNews) -> Bool {
        guard let currentUser = auth.currentUser else { return true }
        return news.author != currentUser.displayName
    }

    private func confirm(news: CommunityNews) async {
        guard let user = auth.currentUser else { return }
        do {
            try await SupabaseNewsService(client: auth.client).confirm(newsID: news.id, userID: user.id)
            store.confirmNews(id: news.id)
            confirmationError = nil
        } catch {
            confirmationError = "No pudimos guardar tu confirmación."
        }
    }
}
