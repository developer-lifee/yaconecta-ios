import SwiftUI

struct MakeOfferSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    let request: LocalRequest

    @State private var priceText: String
    @State private var note: String = ""
    @State private var offererPhone: String = ""
    @State private var errorMessage: String? = nil

    init(request: LocalRequest) {
        self.request = request
        let initialPrice = request.budget ?? 15000
        _priceText = State(initialValue: String(initialPrice))
    }

    private var basePrice: Int {
        request.budget ?? 15000
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Solicitud del Vecino") {
                    HStack(spacing: 12) {
                        Image(systemName: request.category.symbol)
                            .font(.title2)
                            .foregroundStyle(AppTheme.coral)
                            .frame(width: 40, height: 40)
                            .background(AppTheme.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(request.title).font(.subheadline.bold())
                            Text("\(request.author) • \(request.area)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    if let budget = request.budget {
                        HStack {
                            Text("Presupuesto propuesto por cliente:")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(budget.colombianCurrency)
                                .font(.caption.bold())
                                .foregroundStyle(AppTheme.moss)
                        }
                    }
                }

                Section("Proponer o Negociar Tarifa ($)") {
                    TextField("Monto en pesos (ej. 17000)", text: $priceText)
                        .keyboardType(.numberPad)
                        .font(.title3.bold())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ajuste rápido de oferta:")
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button("Base (\(basePrice.colombianCurrency))") {
                                    priceText = String(basePrice)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())

                                Button("+$2.000 (\((basePrice + 2000).colombianCurrency))") {
                                    priceText = String(basePrice + 2000)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())

                                Button("+$5.000 (\((basePrice + 5000).colombianCurrency))") {
                                    priceText = String(basePrice + 5000)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())

                                Button("+$10.000 (\((basePrice + 10000).colombianCurrency))") {
                                    priceText = String(basePrice + 10000)
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Mensaje o Nota Aclaratoria (Opcional)") {
                    TextField("Ej. Llego en 10 min en mototaxi / Te llevo el pedido completo…", text: $note, axis: .vertical)
                        .lineLimit(2...3)
                }

                Section("Teléfono / WhatsApp de Contacto") {
                    HStack {
                        Image(systemName: "phone.fill").foregroundStyle(.green)
                        TextField("WhatsApp (ej. 3101234567)", text: $offererPhone)
                            .keyboardType(.phonePad)
                    }
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Negociar Encargo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enviar Propuesta") {
                        submitOffer()
                    }
                    .font(.headline)
                }
            }
        }
    }

    private func submitOffer() {
        guard let price = Int(priceText), price > 0 else {
            errorMessage = "Ingresa una tarifa válida en pesos."
            return
        }

        let offererName = auth.currentUser?.displayName ?? store.myBusiness?.name ?? "Comerciante / Vecino"
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = cleanNote.isEmpty ? nil : cleanNote
        let cleanPhone = offererPhone.trimmingCharacters(in: .whitespacesAndNewlines)

        store.submitCounterOffer(
            requestID: request.id,
            offererName: offererName,
            offererPhone: cleanPhone.isEmpty ? nil : cleanPhone,
            price: price,
            note: finalNote
        )
        dismiss()
    }
}
