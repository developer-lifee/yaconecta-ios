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
                    TextField("URL de la foto (opcional)", text: $imageURLText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        imageURLText = "https://images.unsplash.com/photo-1582293041079-7814c2f12063?w=800"
                    } label: {
                        Label("Adjuntar foto de muestra", systemImage: "photo.badge.plus")
                            .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)

                    if let url = URL(string: imageURLText), !imageURLText.isEmpty {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                                    .frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingProduct == nil ? "Agregar Producto" : "Editar Producto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
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

        let updated = Product(
            id: existingProduct?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            price: parsedPrice,
            imageURL: imageURL
        )

        if existingProduct != nil {
            store.updateProduct(in: businessID, product: updated)
        } else {
            store.updateProduct(in: businessID, product: updated)
            // also ensure added to products list if new
            store.bulkImportProducts(to: businessID, products: [updated])
        }
    }
}
