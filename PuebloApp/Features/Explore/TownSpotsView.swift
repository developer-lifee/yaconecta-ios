import SwiftUI

struct TownSpotsView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var selectedCategory: SpotCategory?
    @State private var isPresentingCreateSheet = false
    @State private var selectedSpotForReview: TownSpot? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerBanner

                categoryChips

                LazyVStack(spacing: 16) {
                    ForEach(filteredSpots) { spot in
                        SpotCard(spot: spot) {
                            selectedSpotForReview = spot
                        }
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
        .sheet(item: $selectedSpotForReview) { spot in
            AddSpotReviewSheet(spotID: spot.id, spotName: spot.name)
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
    let onAddReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: spot.photoSymbol)
                    .font(.system(size: 24))
                    .foregroundStyle(.orange)
                    .frame(width: 48, height: 48)
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

            if let photoURL = spot.photoURL, !photoURL.isEmpty {
                MediaThumbnailView(urlString: photoURL, height: 170)
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

            Divider()

            // Sección de Reseñas y Experiencias de Visitantes
            if !spot.reviews.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reseñas de visitantes (\(spot.reviews.count)):")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(spot.reviews.prefix(2)) { review in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(review.author).font(.caption.bold())
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= review.rating ? "star.fill" : "star")
                                            .font(.caption2)
                                            .foregroundStyle(.orange)
                                    }
                                }
                                Spacer()
                            }
                            Text(review.comment)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let photoURL = review.photoURL, !photoURL.isEmpty {
                                MediaThumbnailView(urlString: photoURL, height: 100)
                            }
                        }
                        .padding(10)
                        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            Button {
                onAddReview()
            } label: {
                Label("Yo estuve aquí / Agregar reseña o foto", systemImage: "camera.badge.ellipsis")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.coral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(AppTheme.coral.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .cardSurface()
    }
}

struct AddSpotReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    let spotID: UUID
    let spotName: String

    @State private var comment = ""
    @State private var rating = 5
    @State private var mediaURLString = ""
    @State private var selectedImageData: Data? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Mi Experiencia en \(spotName)") {
                    HStack {
                        Text("Calificación:")
                        Spacer()
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                    .onTapGesture {
                                        rating = star
                                    }
                            }
                        }
                    }

                    TextField("¿Cómo te pareció este rincón? (tips, recomendación)", text: $comment, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section("Fotografía de tu visita") {
                    MediaPickerView(
                        title: "Sube una foto tomada en el lugar usando la cámara o selecciónala de tu galería:",
                        mediaURLString: $mediaURLString,
                        selectedImageData: $selectedImageData
                    )
                }
            }
            .navigationTitle("Agregar Reseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let authorName = auth.currentUser?.displayName ?? "Visitante"
                        store.addReviewToSpot(
                            spotID: spotID,
                            comment: comment,
                            rating: rating,
                            photoURL: mediaURLString.isEmpty ? nil : mediaURLString,
                            author: authorName
                        )
                        dismiss()
                    }
                    .disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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
                            photoURL: mediaURLString.isEmpty ? nil : mediaURLString,
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
