import SwiftUI

struct MyBusinessView: View {
    @Environment(MarketplaceStore.self) private var store

    @State private var name: String = ""
    @State private var category: BusinessCategory = .services
    @State private var summary: String = ""
    @State private var deliveryPriceText: String = ""
    @State private var etaMinutesText: String = ""
    @State private var symbol: String = "storefront.fill"
    @State private var colorName: String = "coral"

    @State private var activeSheet: SheetType?

    private enum SheetType: Identifiable {
        case addProduct
        case editProduct(Product)
        case bulkImport

        var id: String {
            switch self {
            case .addProduct: "add-product"
            case .editProduct(let p): "edit-\(p.id.uuidString)"
            case .bulkImport: "bulk-import"
            }
        }
    }

    var body: some View {
        Form {
            Section("Perfil de mi Comercio") {
                TextField("Nombre del negocio (ej. Ferretería El Progreso)", text: $name)
                Picker("Categoría", selection: $category) {
                    ForEach(BusinessCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                    }
                }
                TextField("Resumen o descripción corta", text: $summary, axis: .vertical)
                    .lineLimit(2...3)
                HStack {
                    Text("Costo domicilio ($):")
                    TextField("0", text: $deliveryPriceText)
                        .keyboardType(.numberPad)
                }
                HStack {
                    Text("Tiempo estimado (min):")
                    TextField("20", text: $etaMinutesText)
                        .keyboardType(.numberPad)
                }
                Button("Guardar cambios del perfil") {
                    saveBusinessProfile()
                }
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.coral)
            }

            if let business = store.myBusiness {
                Section {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Mi Estantería (\(business.products.count) productos)")
                                .font(.headline)
                            Text("Productos visibles para los clientes de tu pueblo.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }

                    HStack(spacing: 12) {
                        Button {
                            activeSheet = .addProduct
                        } label: {
                            Label("Nuevo", systemImage: "plus.circle.fill")
                                .font(.subheadline.bold())
                        }

                        Spacer()

                        Button {
                            activeSheet = .bulkImport
                        } label: {
                            Label("Importar Excel/CSV", systemImage: "arrow.down.doc.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.moss)
                        }
                    }
                    .padding(.vertical, 4)

                    if business.products.isEmpty {
                        ContentUnavailableView {
                            Label("Estantería vacía", systemImage: "basket")
                        } description: {
                            Text("Agrega tus primeros productos o importa tu inventario desde un Excel para que la gente los encuentre al buscar.")
                        }
                    } else {
                        ForEach(business.products) { product in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(product.name)
                                        .font(.subheadline.weight(.semibold))
                                    if !product.detail.isEmpty {
                                        Text(product.detail)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                Text(product.price.colombianCurrency)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AppTheme.moss)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteProduct(from: business.id, productID: product.id)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                                Button {
                                    activeSheet = .editProduct(product)
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            } else {
                Section {
                    Button("Crear mi negocio ahora") {
                        saveBusinessProfile()
                    }
                    .font(.headline)
                    .foregroundStyle(AppTheme.coral)
                }
            }
        }
        .navigationTitle("Mi Negocio")
        .onAppear {
            loadExistingProfile()
        }
        .sheet(item: $activeSheet) { sheet in
            if let business = store.myBusiness {
                switch sheet {
                case .addProduct:
                    AddEditProductSheet(businessID: business.id)
                case .editProduct(let product):
                    AddEditProductSheet(businessID: business.id, existingProduct: product)
                case .bulkImport:
                    BulkImportProductsSheet(businessID: business.id)
                }
            }
        }
    }

    private func loadExistingProfile() {
        if let existing = store.myBusiness {
            name = existing.name
            category = existing.category
            summary = existing.summary
            deliveryPriceText = String(existing.deliveryPrice)
            etaMinutesText = String(existing.etaMinutes)
            symbol = existing.symbol
            colorName = existing.colorName
        } else {
            name = "Mi Negocio / Ferretería"
            category = .services
            summary = "Atención directa, productos de calidad y envíos locales."
            deliveryPriceText = "3000"
            etaMinutesText = "20"
        }
    }

    private func saveBusinessProfile() {
        let price = Int(deliveryPriceText.filter(\.isNumber)) ?? 0
        let eta = Int(etaMinutesText.filter(\.isNumber)) ?? 20
        store.createOrUpdateMyBusiness(
            name: name,
            category: category,
            summary: summary,
            deliveryPrice: price,
            etaMinutes: eta,
            symbol: symbol,
            colorName: colorName
        )
    }
}
