import SwiftUI

struct ExploreView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var store = store
        ScrollView {
            LazyVStack(spacing: 24) {
                categories
                businessSection
                townSpotsSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
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
        .searchable(text: $store.searchText, prompt: "¿Qué necesitas en \(store.selectedTown?.name ?? "tu pueblo") hoy?")
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(
                title: "Comercios y Negocios",
                subtitle: "\(store.filteredBusinesses.count) opciones activas en \(store.selectedTown?.name ?? "tu pueblo")"
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeading(title: "Spots del Pueblo", subtitle: "Miradores y parches chill recomendados")
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
                .background(isSelected ? AppTheme.coral : Color(.secondarySystemGroupedBackground), in: Capsule())
                .overlay {
                    if !isSelected {
                        Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct BusinessCard: View {
    let business: Business

    var body: some View {
        HStack(spacing: 15) {
            SmartImageView(
                urlString: business.logoURL,
                width: 64,
                height: 64,
                cornerRadius: 18,
                fallbackSymbol: business.symbol,
                fallbackColor: iconColor
            )

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

                if !business.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(business.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .foregroundStyle(AppTheme.coral)
                                    .background(AppTheme.coral.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                } else {
                    HStack(spacing: 12) {
                        Label("\(business.etaMinutes) min", systemImage: "clock")
                        Label(business.rating.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                        Text(business.deliveryPrice.colombianCurrency)
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.moss)
                }
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
