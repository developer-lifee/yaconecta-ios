import SwiftUI

struct ExploreView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var store = store
        ScrollView {
            LazyVStack(spacing: 24) {
                welcomeBanner
                categories
                businessSection
                townSpotsSection
                nearbyRequests
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("YaConecta")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { TownButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.sheet = .createRequest
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Publicar solicitud")
                .accessibilityIdentifier("create-request-button")
            }
        }
        .searchable(text: $store.searchText, prompt: "¿Qué necesitas hoy?")
    }

    private var welcomeBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Todo el pueblo,\na una conversación")
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Compra, pide un expreso o encuentra quién te ayude cerca.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.88))
            Button {
                router.sheet = .createRequest
            } label: {
                Label("Publicar lo que necesito", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.coral)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white, in: Capsule())
            }
            .accessibilityIdentifier("hero-create-request-button")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            LinearGradient(colors: [AppTheme.coral, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .padding(.top, 8)
    }

    private var categories: some View {
        VStack(spacing: 12) {
            SectionHeading(title: "Explora por categoría")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    CategoryChip(title: "Todo", symbol: "square.grid.2x2.fill", isSelected: store.selectedCategory == nil) {
                        store.selectedCategory = nil
                    }
                    ForEach(BusinessCategory.allCases) { category in
                        CategoryChip(title: category.rawValue, symbol: category.symbol, isSelected: store.selectedCategory == category) {
                            store.selectedCategory = category
                        }
                    }
                }
            }
        }
    }

    private var businessSection: some View {
        VStack(spacing: 12) {
            SectionHeading(
                title: "Abiertos ahora",
                subtitle: "\(store.filteredBusinesses.count) opciones en \(store.selectedTown?.name ?? "tu pueblo")"
            )
            if store.filteredBusinesses.isEmpty {
                ContentUnavailableView.search(text: store.searchText)
                    .frame(minHeight: 180)
            } else {
                ForEach(store.filteredBusinesses) { business in
                    Button {
                        router.navigate(to: .business(business))
                    } label: {
                        BusinessCard(business: business)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("business-\(business.id.uuidString)")
                }
            }
        }
    }

    private var townSpotsSection: some View {
        VStack(spacing: 12) {
            HStack {
                SectionHeading(title: "Spots del Pueblo", subtitle: "Lugares foto y parches chill recomendados")
                Spacer()
                Button("Ver todos") {
                    router.navigate(to: .townSpots)
                }
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.coral)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(store.townSpots) { spot in
                        Button {
                            router.navigate(to: .townSpots)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: spot.photoSymbol)
                                        .foregroundStyle(.orange)
                                    Spacer()
                                    Label("\(spot.likesCount)", systemImage: "heart.fill")
                                        .font(.caption2.bold())
                                        .foregroundStyle(.red)
                                }
                                Text(spot.name)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.ink)
                                    .lineLimit(1)
                                Text(spot.locationNote)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding(14)
                            .frame(width: 210, alignment: .leading)
                            .cardSurface()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var nearbyRequests: some View {
        VStack(spacing: 12) {
            SectionHeading(title: "La gente está buscando", subtitle: "Solicitudes recientes cerca de ti")
            ForEach(store.townRequests.filter { !$0.isMine }.prefix(2)) { request in
                Button {
                    router.navigate(to: .request(request))
                } label: {
                    RequestRow(request: request)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CategoryChip: View {
    let title: String
    let symbol: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? .white : AppTheme.ink)
                .background(isSelected ? AppTheme.ink : .white, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct BusinessCard: View {
    let business: Business

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: business.symbol)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 68, height: 68)
                .background(iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(business.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
                Text(business.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 12) {
                    Label("\(business.etaMinutes) min", systemImage: "clock")
                    Label(business.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    Text(business.deliveryPrice.colombianCurrency)
                }
                .font(.caption)
                .foregroundStyle(AppTheme.moss)
            }
        }
        .padding(14)
        .cardSurface()
    }

    private var iconColor: Color {
        switch business.colorName {
        case "moss": AppTheme.moss
        case "sky": .blue
        case "sun": .orange
        default: AppTheme.coral
        }
    }
}
