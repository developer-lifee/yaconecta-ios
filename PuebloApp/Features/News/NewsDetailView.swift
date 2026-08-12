import SwiftUI

struct NewsDetailView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    let newsID: CommunityNews.ID
    @State private var showReportConfirmation = false
    @State private var confirmationError: String?

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

                        if let imageURLString = news.imageURL, let url = URL(string: imageURLString) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Evidencia fotográfica:")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                                    case .failure:
                                        Label("No fue posible cargar la imagen de evidencia", systemImage: "photo.badge.exclamationmark")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    default:
                                        ProgressView()
                                            .frame(maxWidth: .infinity, minHeight: 120)
                                    }
                                }
                            }
                        }

                        Text(news.body)
                            .font(.body)
                            .lineSpacing(5)

                        Divider()
                        Label(news.location, systemImage: "mappin.and.ellipse")
                        Label("Publicado por \(news.author)", systemImage: "person.crop.circle")
                        if let source = news.sourceNote {
                            Label(source, systemImage: "link")
                        }
                        Divider()
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
            } else {
                ContentUnavailableView("Noticia no disponible", systemImage: "newspaper")
            }
        }
        .navigationTitle("Noticia")
        .navigationBarTitleDisplayMode(.inline)
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
