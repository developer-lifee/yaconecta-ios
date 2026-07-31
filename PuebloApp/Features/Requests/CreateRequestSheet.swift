import SwiftUI

struct CreateRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @State private var draft = RequestDraft()
    @State private var budgetText = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("¿Qué necesitas?") {
                    TextField("Ej. Expreso hasta la terminal", text: $draft.title)
                        .accessibilityIdentifier("request-title-field")
                    Picker("Categoría", selection: $draft.category) {
                        ForEach(RequestCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbol).tag(category)
                        }
                    }
                    TextField("Cuéntalo con suficiente detalle", text: $draft.detail, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("request-detail-field")
                }

                Section("Lugar y presupuesto") {
                    TextField("Barrio, sector o vereda", text: $draft.area)
                    TextField("Presupuesto opcional", text: $budgetText)
                        .keyboardType(.numberPad)
                        .onChange(of: budgetText) { _, newValue in
                            draft.budget = Int(newValue.filter(\.isNumber))
                        }
                }

                Section {
                    Label(
                        "Tu teléfono y ubicación exacta solo se compartirán cuando aceptes una propuesta.",
                        systemImage: "lock.shield.fill"
                    )
                    .font(.footnote)
                    .foregroundStyle(AppTheme.moss)
                }
            }
            .navigationTitle("Nueva solicitud")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Publicar") {
                        store.publish(draft)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!draft.isValid)
                    .accessibilityIdentifier("publish-request-button")
                }
            }
        }
    }
}
