import SwiftUI

struct AddEditProductSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store

    let businessID: UUID
    let existingProduct: Product?

    @State private var name: String
    @State private var detail: String
    @State private var priceText: String

    init(businessID: UUID, existingProduct: Product? = nil) {
        self.businessID = businessID
        self.existingProduct = existingProduct
        _name = State(initialValue: existingProduct?.name ?? "")
        _detail = State(initialValue: existingProduct?.detail ?? "")
        _priceText = State(initialValue: existingProduct != nil ? String(existingProduct!.price) : "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información del Producto") {
                    TextField("Nombre del producto (ej. Tanque 500L, Cemento)", text: $name)
                    TextField("Detalle o descripción (ej. Marca, tamaño, color)", text: $detail, axis: .vertical)
                        .lineLimit(3...5)
                    HStack {
                        Text("Precio ($ COP):")
                            .foregroundStyle(.secondary)
                        TextField("0", text: $priceText)
                            .keyboardType(.numberPad)
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
        if let existing = existingProduct {
            let updated = Product(
                id: existing.id,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                price: parsedPrice
            )
            store.updateProduct(in: businessID, product: updated)
        } else {
            store.addProduct(
                to: businessID,
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                price: parsedPrice
            )
        }
    }
}
