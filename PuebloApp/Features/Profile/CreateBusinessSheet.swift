import SwiftUI

struct CreateBusinessSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth

    @State private var name = ""
    @State private var category: BusinessCategory = .food
    @State private var summary = ""
    @State private var tagInput = ""
    @State private var tags: [String] = ["Dulcería", "Golosinas"]
    @State private var whatsappNumber = ""
    @State private var instagramHandle = ""
    @State private var deliveryPriceText = "3000"
    @State private var etaMinutesText = "20"

    var onCreated: ((Business) -> Void)?

    private let suggestedTags = ["Dulcería", "Golosinas", "Restaurante", "Remate", "Ferretería", "Panadería", "Heladería", "Miscelánea", "Peluquería", "Expresos", "Finca"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos Principales") {
                    TextField("Nombre del negocio (ej. Dulcería La Granja)", text: $name)
                    Picker("Categoría Base", selection: $category) {
                        ForEach(BusinessCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    TextField("Descripción corta / Resumen de lo que vendes", text: $summary, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Etiquetas / Tags Personalizados") {
                    Text("Agrega etiquetas para que los clientes te encuentren fácilmente al buscar (ej. Dulcería, Postres, Regalos):")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("Nueva etiqueta", text: $tagInput)
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

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sugerencias rápidas:").font(.caption2.bold()).foregroundStyle(.secondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(suggestedTags, id: \.self) { stag in
                                    Button(stag) {
                                        if !tags.contains(stag) {
                                            tags.append(stag)
                                        }
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                                }
                            }
                        }
                    }
                }

                Section("Atención al Cliente y WhatsApp") {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.green)
                        TextField("Número WhatsApp (ej. 3101234567)", text: $whatsappNumber)
                            .keyboardType(.phonePad)
                    }
                    HStack {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(.purple)
                        TextField("Instagram (ej. @dulceria_cubarral)", text: $instagramHandle)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Servicio de Domicilio") {
                    HStack {
                        Text("Costo domicilio ($)")
                        Spacer()
                        TextField("Ej. 3000", text: $deliveryPriceText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Tiempo est. (minutos)")
                        Spacer()
                        TextField("Ej. 20", text: $etaMinutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Registrar Mi Negocio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear Negocio") {
                        let deliveryPrice = Int(deliveryPriceText) ?? 3000
                        let etaMinutes = Int(etaMinutesText) ?? 20
                        let ownerID = auth.currentUser?.id
                        if let created = store.createBusiness(
                            name: name,
                            category: category,
                            summary: summary,
                            tags: tags,
                            whatsappNumber: whatsappNumber,
                            instagramHandle: instagramHandle,
                            deliveryPrice: deliveryPrice,
                            etaMinutes: etaMinutes,
                            ownerID: ownerID
                        ) {
                            onCreated?(created)
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addTag() {
        let clean = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, !tags.contains(clean) else { return }
        tags.append(clean)
        tagInput = ""
    }
}
