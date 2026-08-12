import SwiftUI

struct TownSpotsView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var selectedCategory: SpotCategory?
    @State private var isPresentingCreateSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBanner

                categoryChips

                LazyVStack(spacing: 16) {
                    ForEach(filteredSpots) { spot in
                        SpotCard(spot: spot)
                    }
                }
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Spots del Pueblo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreateSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateSheet) {
            CreateSpotSheet()
        }
    }

    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Rincones y Parches Secretos", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                Spacer()
            }
            Text("Lugares únicos recomendados por vecinos")
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)
            Text("Ideal para visitantes o para descubrir nuevos parches chill en \(store.selectedTown?.name ?? "tu pueblo").")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .cardSurface()
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    selectedCategory = nil
                } label: {
                    Text("Todos")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedCategory == nil ? .white : AppTheme.ink)
                        .background(selectedCategory == nil ? AppTheme.coral : Color(.secondarySystemGroupedBackground), in: Capsule())
                }

                ForEach(SpotCategory.allCases) { cat in
                    Button {
                        selectedCategory = cat
                    } label: {
                        Label(cat.rawValue, systemImage: cat.symbol)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .foregroundStyle(selectedCategory == cat ? .white : AppTheme.ink)
                            .background(selectedCategory == cat ? AppTheme.coral : Color(.secondarySystemGroupedBackground), in: Capsule())
                    }
                }
            }
        }
    }

    private var filteredSpots: [TownSpot] {
        if let cat = selectedCategory {
            return store.townSpots.filter { $0.category == cat }
        }
        return store.townSpots
    }
}

private struct SpotCard: View {
    @Environment(MarketplaceStore.self) private var store
    let spot: TownSpot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: spot.photoSymbol)
                    .font(.system(size: 26))
                    .foregroundStyle(.orange)
                    .frame(width: 52, height: 52)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    HStack {
                        Label(spot.category.rawValue, systemImage: spot.category.symbol)
                        Text("•  Por \(spot.author)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(spot.description)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink.opacity(0.9))
                .lineLimit(4)

            HStack {
                Label(spot.locationNote, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(AppTheme.moss)
                Spacer()
                Button {
                    store.toggleSpotLike(id: spot.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: spot.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(spot.isLiked ? .red : .secondary)
                        Text("\(spot.likesCount)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .cardSurface()
    }
}

struct CreateSpotSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var name = ""
    @State private var description = ""
    @State private var category: SpotCategory = .photo
    @State private var locationNote = ""
    @State private var mediaURLString = ""
    @State private var selectedImageData: Data? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Información del Spot") {
                    TextField("Nombre del lugar (ej. Mirador del Cerro)", text: $name)
                    Picker("Categoría", selection: $category) {
                        ForEach(SpotCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    TextField("Ubicación o referencia (ej. A 10 min de la plaza)", text: $locationNote)
                    TextField("¿Por qué es especial este lugar? (detalles, recomendaciones)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Fotografía / Video del Spot") {
                    MediaPickerView(
                        title: "Adjunta la foto o video del lugar usando la cámara o seleccionando desde tu galería:",
                        mediaURLString: $mediaURLString,
                        selectedImageData: $selectedImageData
                    )
                }
            }
            .navigationTitle("Publicar Spot Secretito")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publicar") {
                        let authorName = auth.currentUser?.displayName ?? "Vecino"
                        store.publishSpot(
                            name: name,
                            description: description,
                            category: category,
                            locationNote: locationNote,
                            author: authorName
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
