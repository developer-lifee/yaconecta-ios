import SwiftUI

struct BulkImportProductsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store

    let businessID: UUID

    @State private var rawText = ""
    @State private var parsedProducts: [Product] = []

    private let sampleData = """
Tanque plástico 500L, Tanque azul con tapa para reserva de agua, 240000
Tanque 1000L, Tanque reforzado con multiconector, 450000
Bomba de agua 0.5HP, Bomba periférica para uso doméstico, 120000
Juego de destornilladores, 6 piezas de cromo vanadio aislados, 35000
Cemento gris 50kg, Bulto de cemento estructurado, 32000
"""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Carga Masiva desde Excel / CSV")
                            .font(.headline)
                        Spacer()
                        Button("Cargar ejemplo") {
                            rawText = sampleData
                            parseText()
                        }
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.coral)
                    }
                    Text("Copia y pega la lista de productos de tu negocio. Cada línea debe seguir el formato:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Nombre, Descripción o Detalle, Precio")
                        .font(.caption.bold())
                        .foregroundStyle(AppTheme.coral)
                        .padding(8)
                        .background(AppTheme.coral.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal)
                .padding(.top, 12)

                TextEditor(text: $rawText)
                    .font(.caption.monospaced())
                    .padding(8)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .frame(height: 180)
                    .onChange(of: rawText) { _, _ in
                        parseText()
                    }

                HStack {
                    Text("Vista previa (\(parsedProducts.count) productos detectados)")
                        .font(.subheadline.bold())
                    Spacer()
                }
                .padding(.horizontal)

                List {
                    ForEach(parsedProducts) { product in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(product.name)
                                    .font(.subheadline.bold())
                                if !product.detail.isEmpty {
                                    Text(product.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(product.price.colombianCurrency)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.moss)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Importar Inventario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Importar (\(parsedProducts.count))") {
                        if !parsedProducts.isEmpty {
                            store.bulkImportProducts(to: businessID, products: parsedProducts)
                        }
                        dismiss()
                    }
                    .disabled(parsedProducts.isEmpty)
                }
            }
            .onAppear {
                parseText()
            }
        }
    }

    private func parseText() {
        let lines = rawText.components(separatedBy: .newlines)
        var results: [Product] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let parts: [String]
            if trimmed.contains("\t") {
                parts = trimmed.components(separatedBy: "\t")
            } else if trimmed.contains(";") {
                parts = trimmed.components(separatedBy: ";")
            } else {
                parts = trimmed.components(separatedBy: ",")
            }

            guard let firstPart = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines), !firstPart.isEmpty else {
                continue
            }

            let name = firstPart
            var detail = ""
            var price = 0

            if parts.count >= 3 {
                detail = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                price = Int(parts[2].filter(\.isNumber)) ?? 0
            } else if parts.count == 2 {
                let second = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if let parsedPrice = Int(second.filter(\.isNumber)), parsedPrice > 0 {
                    price = parsedPrice
                } else {
                    detail = second
                }
            }

            results.append(Product(id: UUID(), name: name, detail: detail, price: price))
        }

        parsedProducts = results
    }
}
