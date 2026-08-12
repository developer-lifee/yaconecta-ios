import SwiftUI

struct NewsView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @Environment(AppRouter.self) private var router
    @State private var category: NewsCategory?
    @State private var syncError: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                safetyNote
                if let syncError {
                    Label(syncError, systemImage: "wifi.exclamationmark")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                categoryPicker

                ForEach(filteredNews) { item in
                    Button {
                        router.navigate(to: .news(item))
                    } label: {
                        NewsCard(news: item)
                    }
                    .buttonStyle(.plain)
                }

                if filteredNews.isEmpty {
                    ContentUnavailableView(
                        "No hay noticias en esta categoría",
                        systemImage: "newspaper",
                        description: Text("Puedes informar algo importante a tus vecinos.")
                    )
                    .frame(minHeight: 260)
                }
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Noticias locales")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { TownButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.sheet = auth.isSignedIn ? .createNews : .signIn
                } label: {
                    Label("Informar", systemImage: "plus")
                }
                .accessibilityIdentifier("create-news-button")
            }
        }
        .task(id: store.selectedTownID) {
            await synchronizeNews()
        }
    }

    private var filteredNews: [CommunityNews] {
        store.townNews.filter { category == nil || $0.category == category }
    }

    private func synchronizeNews() async {
        guard let townID = store.selectedTown?.id else { return }
        let service = SupabaseNewsService(client: auth.client)
        guard service.isConfigured else { return }
        do {
            store.replaceNews(for: townID, with: try await service.fetchNews(townID: townID))
            syncError = nil
        } catch {
            syncError = "Mostrando datos guardados; no fue posible actualizar el pueblo."
        }
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.moss)
            VStack(alignment: .leading, spacing: 4) {
                Text("Información con contexto")
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                Text("Diferenciamos reportes sin verificar, confirmaciones de vecinos y fuentes verificadas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(AppTheme.sky, in: RoundedRectangle(cornerRadius: 18))
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                NewsCategoryChip(title: "Todas", symbol: "square.grid.2x2.fill", selected: category == nil) {
                    category = nil
                }
                ForEach(NewsCategory.allCases) { item in
                    NewsCategoryChip(title: item.rawValue, symbol: item.symbol, selected: category == item) {
                        category = item
                    }
                }
            }
        }
    }
}

private struct NewsCategoryChip: View {
    let title: String
    let symbol: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .foregroundStyle(selected ? .white : AppTheme.ink)
                .background(selected ? AppTheme.coral : Color(.secondarySystemGroupedBackground), in: Capsule())
                .overlay {
                    if !selected {
                        Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

struct NewsCard: View {
    let news: CommunityNews

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label(news.category.rawValue, systemImage: news.category.symbol)
                    .font(.caption.bold())
                    .foregroundStyle(categoryColor)
                Spacer()
                if news.isRegional {
                    Label("REGIONAL", systemImage: "globe.americas.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.14), in: Capsule())
                }
                if news.urgency == .urgent {
                    Text("URGENTE")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red, in: Capsule())
                }
            }
            Text(news.title)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.leading)

            if let imageURLString = news.imageURL, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    default:
                        EmptyView()
                    }
                }
            }

            Text(news.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
            HStack {
                Label(news.location, systemImage: "mappin")
                Spacer()
                Text(news.createdAt, style: .relative)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            VerificationBadge(status: news.verification, confirmations: news.confirmationCount)
        }
        .padding(16)
        .cardSurface()
    }

    private var categoryColor: Color {
        switch news.category {
        case .roads: .orange
        case .emergency: .red
        case .publicService: .blue
        case .community: AppTheme.moss
        case .mourning: .purple
        }
    }
}

struct VerificationBadge: View {
    let status: VerificationStatus
    let confirmations: Int

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.caption.bold())
            .foregroundStyle(color)
    }

    private var label: String {
        switch status {
        case .unverified: "Sin verificar"
        case .communityConfirmed: "Confirmada por \(confirmations) vecinos"
        case .verified: "Fuente verificada"
        }
    }

    private var symbol: String {
        switch status {
        case .unverified: "questionmark.circle"
        case .communityConfirmed: "person.2.badge.gearshape.fill"
        case .verified: "checkmark.seal.fill"
        }
    }

    private var color: Color {
        switch status {
        case .unverified: .orange
        case .communityConfirmed: .blue
        case .verified: AppTheme.moss
        }
    }
}
