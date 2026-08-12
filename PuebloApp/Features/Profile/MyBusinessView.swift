import SwiftUI

struct MyBusinessView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var activeSheet: SheetType?
    @State private var isPresentingCreateBusiness = false
    @State private var offerSentAuthor: String? = nil

    private enum SheetType: Identifiable {
        case addProduct
        case editProduct(Product)
        case bulkImport
        case editProfile
        case makeOffer(LocalRequest)

        var id: String {
            switch self {
            case .addProduct: "add-product"
            case .editProduct(let p): "edit-\(p.id.uuidString)"
            case .bulkImport: "bulk-import"
            case .editProfile: "edit-profile"
            case .makeOffer(let r): "offer-\(r.id.uuidString)"
            }
        }
    }

    var body: some View {
        Group {
            if let business = currentBusiness {
                ScrollView {
                    VStack(spacing: 18) {
                        businessHeaderBanner(business)
                        kpiGrid(business)
                        productsSection(business)
                        localOpportunitiesSection
                    }
                    .padding(18)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                noBusinessView
            }
        }
        .navigationTitle("Mi Negocio")
        .sheet(item: $activeSheet) { sheet in
            if let business = currentBusiness {
                switch sheet {
                case .addProduct:
                    AddEditProductSheet(businessID: business.id)
                case .editProduct(let product):
                    AddEditProductSheet(businessID: business.id, existingProduct: product)
                case .bulkImport:
                    BulkImportProductsSheet(businessID: business.id)
                case .editProfile:
                    EditBusinessProfileSheet(business: business)
                case .makeOffer(let request):
                    MakeOfferSheet(request: request)
                }
            }
        }
        .sheet(isPresented: $isPresentingCreateBusiness) {
            CreateBusinessSheet { _ in }
        }
        .alert("¡Propuesta Comercial Enviada!", isPresented: Binding(
            get: { offerSentAuthor != nil },
            set: { if !$0 { offerSentAuthor = nil } }
        )) {
            Button("Entendido", role: .cancel) {}
        } message: {
            if let author = offerSentAuthor {
                Text("Le notificamos a \(author) que tu negocio está disponible para atender su encargo en Cubarral.")
            }
        }
    }

    // MARK: - Banner Header del Negocio
    private func businessHeaderBanner(_ business: Business) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                SmartImageView(
                    urlString: business.logoURL,
                    width: 72,
                    height: 72,
                    cornerRadius: 20,
                    fallbackSymbol: business.symbol,
                    fallbackColor: AppTheme.coral
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(business.name)
                            .font(.title3.bold())
                            .foregroundStyle(AppTheme.ink)
                            .lineLimit(1)
                        Text(business.category.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .foregroundStyle(AppTheme.coral)
                            .background(AppTheme.coral.opacity(0.12), in: Capsule())
                    }

                    Text(business.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        Label("Abierto hoy", systemImage: "circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.green)

                        Label("\(business.rating.formatted(.number.precision(.fractionLength(1)))) (\(business.reviewCount))", systemImage: "star.fill")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.moss)
                    }
                }
                Spacer()
            }

            Divider()

            Button {
                activeSheet = .editProfile
            } label: {
                Label("Editar Configuración Comercial", systemImage: "slider.horizontal.3")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.coral)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .cardSurface()
    }

    // MARK: - Tarjetas Métricas KPI
    private func kpiGrid(_ business: Business) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            kpiCard(
                title: "Estantería",
                value: "\(business.products.count) productos",
                icon: "basket.fill",
                color: AppTheme.coral
            )
            kpiCard(
                title: "WhatsApp",
                value: business.whatsappNumber != nil ? "Conectado" : "Sin número",
                icon: "message.fill",
                color: business.whatsappNumber != nil ? .green : .orange
            )
            kpiCard(
                title: "Domicilio",
                value: "\(business.deliveryPrice.colombianCurrency)",
                icon: "motorcycle.fill",
                color: AppTheme.moss
            )
            kpiCard(
                title: "Oportunidades",
                value: "\(store.townRequests.count) activas",
                icon: "sparkles",
                color: .blue
            )
        }
    }

    private func kpiCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.bold())
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(12)
        .cardSurface()
    }

    // MARK: - Sección Estantería & Inventario
    private func productsSection(_ business: Business) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Estantería de Productos (\(business.products.count))")
                        .font(.headline)
                    Text("Tus productos visibles para los vecinos del pueblo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 12) {
                Button {
                    activeSheet = .addProduct
                } label: {
                    Label("Nuevo Producto", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    activeSheet = .bulkImport
                } label: {
                    Label("Importar Excel", systemImage: "arrow.down.doc.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.moss)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.moss.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Spacer()
            }

            if business.products.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "basket")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("Estantería vacía")
                        .font(.headline)
                    Text("Agrega tus primeros productos o importa tu inventario para que los vecinos te compren en Cubarral.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .cardSurface()
            } else {
                VStack(spacing: 10) {
                    ForEach(business.products) { product in
                        HStack(spacing: 12) {
                            SmartImageView(
                                urlString: product.imageURL,
                                width: 46,
                                height: 46,
                                cornerRadius: 10,
                                fallbackSymbol: "cube.box.fill",
                                fallbackColor: AppTheme.coral
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.name)
                                    .font(.subheadline.weight(.semibold))
                                if !product.detail.isEmpty {
                                    Text(product.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                            Text(product.price.colombianCurrency)
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.moss)

                            Menu {
                                Button {
                                    activeSheet = .editProduct(product)
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    store.deleteProduct(from: business.id, productID: product.id)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .padding(4)
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(12)
                .cardSurface()
            }
        }
    }

    // MARK: - Oportunidades & Solicitudes de Vecinos
    private var localOpportunitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Oportunidades de Venta en el Pueblo (\(store.townRequests.count))")
                    .font(.headline)
                Text("Encargos y mandados que los vecinos necesitan hoy:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if store.townRequests.isEmpty {
                Text("No hay encargos pendientes por ahora en Cubarral.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(16)
                    .cardSurface()
            } else {
                VStack(spacing: 10) {
                    ForEach(store.townRequests.prefix(4)) { req in
                        HStack(spacing: 12) {
                            Image(systemName: req.category.symbol)
                                .font(.title3)
                                .foregroundStyle(AppTheme.coral)
                                .frame(width: 38, height: 38)
                                .background(AppTheme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(req.title)
                                    .font(.subheadline.bold())
                                Text("\(req.author) • \(req.detail)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button("Ofrecer / Negociar") {
                                activeSheet = .makeOffer(req)
                            }
                            .font(.caption.bold())
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.moss)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(12)
                .cardSurface()
            }
        }
    }

    private var noBusinessView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "storefront.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.coral)

            VStack(spacing: 8) {
                Text("Crea y promociona tu negocio")
                    .font(.title2.bold())
                Text("Da a conocer tu dulcería, remate, restaurante, panadería o servicio técnico a todos los vecinos del pueblo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                isPresentingCreateBusiness = true
            } label: {
                Label("Registrar Mi Negocio Ahora", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .padding(.top, 10)

            Spacer()
        }
        .padding(20)
    }

    private var currentBusiness: Business? {
        if let user = auth.currentUser, let b = store.businesses.first(where: { $0.ownerID == user.id }) {
            return b
        }
        return store.myBusiness
    }
}
