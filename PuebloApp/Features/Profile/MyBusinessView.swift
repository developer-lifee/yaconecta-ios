import SwiftUI

struct MyBusinessView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var name: String = ""
    @State private var category: BusinessCategory = .food
    @State private var summary: String = ""
    @State private var deliveryPriceText: String = ""
    @State private var etaMinutesText: String = ""
    @State private var whatsappNumber: String = ""
    @State private var instagramHandle: String = ""
    @State private var tagInput: String = ""
    @State private var tags: [String] = []

    @State private var activeSheet: SheetType?
    @State private var isPresentingCreateBusiness = false

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
        Group {
            if let business = currentBusiness {
                Form {
                    Section("Perfil de Comercio") {
                        TextField("Nombre del negocio", text: $name)
                        Picker("Categoría Base", selection: $category) {
                            ForEach(BusinessCategory.allCases) { cat in
                                Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                            }
                        }
                        TextField("Resumen o descripción corta", text: $summary, axis: .vertical)
                            .lineLimit(2...3)
                    }

                    Section("Canal de Atención & WhatsApp") {
                        HStack {
                            Image(systemName: "phone.fill").foregroundStyle(.green)
                            TextField("WhatsApp (ej. 3101234567)", text: $whatsappNumber)
                                .keyboardType(.phonePad)
                        }
                        HStack {
                            Image(systemName: "camera.fill").foregroundStyle(.purple)
                            TextField("Instagram (ej. @dulceria_cubarral)", text: $instagramHandle)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        HStack {
                            Text("Costo domicilio ($):")
                            Spacer()
                            TextField("3000", text: $deliveryPriceText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        HStack {
                            Text("Tiempo estimado (min):")
                            Spacer()
                            TextField("20", text: $etaMinutesText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                        Button("Guardar Configuración Comercial") {
                            saveBusinessProfile(businessID: business.id)
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.coral)
                    }

                    Section("Etiquetas / Tags de Búsqueda") {
                        HStack {
                            TextField("Nueva etiqueta (ej. Dulcería)", text: $tagInput)
                            Button("Agregar") {
                                addTag()
                            }
                            .disabled(tagInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                            Button {
                                                tags.removeAll { $0 == tag }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .font(.caption.bold())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .foregroundStyle(.white)
                                        .background(AppTheme.coral, in: Capsule())
                                    }
                                }
                            }
                        }
                    }

                    Section("Estantería de Productos (\(business.products.count))") {
                        HStack(spacing: 12) {
                            Button {
                                activeSheet = .addProduct
                            } label: {
                                Label("Nuevo Producto", systemImage: "plus.circle.fill")
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
                                Text("Agrega tus primeros productos o importa tu inventario desde Excel para que los vecinos te compren en Cubarral.")
                            }
                        } else {
                            ForEach(business.products) { product in
                                HStack(spacing: 12) {
                                    if let urlString = product.imageURL, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                                    .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                            } else {
                                                Color.gray.opacity(0.2).frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                        }
                                    } else {
                                        Image(systemName: "cube.box.fill")
                                            .font(.title2).foregroundStyle(AppTheme.coral)
                                            .frame(width: 44, height: 44)
                                            .background(AppTheme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                                    }

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

                    Section("Notificaciones & Solicitudes de Oportunidad") {
                        Text("Vecinos que están buscando encargos o servicios en Cubarral:")
                            .font(.caption).foregroundStyle(.secondary)

                        ForEach(store.townRequests.prefix(3)) { req in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(req.title).font(.subheadline.bold())
                                    Text(req.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer()
                                Button("Ofrecer") {
                                    // Abrir oferta rápida
                                }
                                .font(.caption.bold())
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }
            } else {
                noBusinessView
            }
        }
        .navigationTitle("Mi Negocio")
        .onAppear {
            loadExistingProfile()
        }
        .sheet(item: $activeSheet) { sheet in
            if let business = currentBusiness {
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
        .sheet(isPresented: $isPresentingCreateBusiness) {
            CreateBusinessSheet { newBusiness in
                loadBusinessProfile(newBusiness)
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

    private func loadExistingProfile() {
        if let b = currentBusiness {
            name = b.name
            category = b.category
            summary = b.summary
            deliveryPriceText = String(b.deliveryPrice)
            etaMinutesText = String(b.etaMinutes)
            whatsappNumber = b.whatsappNumber ?? ""
            instagramHandle = b.instagramHandle ?? ""
            tags = b.tags
        }
    }

    private func loadBusinessProfile(_ b: Business) {
        name = b.name
        category = b.category
        summary = b.summary
        deliveryPriceText = String(b.deliveryPrice)
        etaMinutesText = String(b.etaMinutes)
        whatsappNumber = b.whatsappNumber ?? ""
        instagramHandle = b.instagramHandle ?? ""
        tags = b.tags
    }

    private func saveBusinessProfile(businessID: UUID) {
        store.updateBusinessContact(
            businessID: businessID,
            whatsappNumber: whatsappNumber.isEmpty ? nil : whatsappNumber,
            instagramHandle: instagramHandle.isEmpty ? nil : instagramHandle,
            tags: tags
        )
    }

    private func addTag() {
        let clean = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !tags.contains(clean) else { return }
        tags.append(clean)
        tagInput = ""
    }
}
