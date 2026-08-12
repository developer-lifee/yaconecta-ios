import SwiftUI

struct AddEditProductSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store

    let businessID: UUID
    let existingProduct: Product?

    @State private var name: String
    @State private var detail: String
    @State private var priceText: String
    @State private var imageURLText: String

    init(businessID: UUID, existingProduct: Product? = nil) {
        self.businessID = businessID
        self.existingProduct = existingProduct
        _name = State(initialValue: existingProduct?.name ?? "")
        _detail = State(initialValue: existingProduct?.detail ?? "")
        _priceText = State(initialValue: existingProduct != nil ? String(existingProduct!.price) : "")
        _imageURLText = State(initialValue: existingProduct?.imageURL ?? "")
    }

    private let sampleImages = [
        ("🍬 Dulces / Chocolates", "https://images.unsplash.com/photo-1582293041079-7814c2f12063?w=800"),
        ("🍱 Alimentos", "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800"),
        ("🥤 Bebidas", "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=800"),
        ("🛠️ Herramientas", "https://images.unsplash.com/photo-1581147036324-c17ac41dfa6c?w=800")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Información del Producto") {
                    TextField("Nombre del producto (ej. Caja de Chocolates, Arequipe)", text: $name)
                    TextField("Detalle o descripción (ej. Tamaño, sabores, marca)", text: $detail, axis: .vertical)
                        .lineLimit(3...5)
                    HStack {
                        Text("Precio ($ COP):")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $priceText)
                            .keyboardType(.numberPad)
                    }
                }

                Section("Fotografía del Producto") {
                    TextField("URL de foto o imagen de producto", text: $imageURLText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Seleccionar imagen de muestra rápida:").font(.caption2.bold()).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(sampleImages, id: \.1) { label, urlStr in
                                    Button(label) {
                                        imageURLText = urlStr
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                                }
                            }
                        }
                    }

                    if let url = URL(string: imageURLText), !imageURLText.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Vista previa:").font(.caption.bold()).foregroundStyle(.secondary)
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 140)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 80)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingProduct == nil ? "Nuevo Producto" : "Editar Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar Producto") {
                        saveProduct()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveProduct() {
        let parsedPrice = Int(priceText.filter(\.isNumber)) ?? 0
        let cleanImage = imageURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageURL = cleanImage.isEmpty ? nil : cleanImage

        let product = Product(
            id: existingProduct?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            price: parsedPrice,
            imageURL: imageURL
        )

        if existingProduct != nil {
            store.updateProduct(in: businessID, product: product)
        } else {
            store.addProduct(to: businessID, product: product)
        }
    }
}
