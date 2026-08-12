import SwiftUI

struct EditBusinessProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store

    let business: Business

    @State private var name: String
    @State private var category: BusinessCategory
    @State private var summary: String
    @State private var logoURLText: String
    @State private var selectedImageData: Data? = nil
    @State private var whatsappNumber: String
    @State private var instagramHandle: String
    @State private var deliveryPriceText: String
    @State private var etaMinutesText: String
    @State private var tagInput: String = ""
    @State private var tags: [String]

    private let suggestedTags = ["Dulcería", "Golosinas", "Restaurante", "Remate", "Ferretería", "Panadería", "Heladería", "Miscelánea", "Peluquería", "Expresos", "Finca"]

    init(business: Business) {
        self.business = business
        _name = State(initialValue: business.name)
        _category = State(initialValue: business.category)
        _summary = State(initialValue: business.summary)
        _logoURLText = State(initialValue: business.logoURL ?? "")
        _whatsappNumber = State(initialValue: business.whatsappNumber ?? "")
        _instagramHandle = State(initialValue: business.instagramHandle ?? "")
        _deliveryPriceText = State(initialValue: String(business.deliveryPrice))
        _etaMinutesText = State(initialValue: String(business.etaMinutes))
        _tags = State(initialValue: business.tags)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos Básicos del Comercio") {
                    TextField("Nombre del negocio", text: $name)
                    Picker("Categoría Base", selection: $category) {
                        ForEach(BusinessCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    TextField("Resumen o descripción corta", text: $summary, axis: .vertical)
                        .lineLimit(2...3)
                }

                Section("Logo / Foto de Perfil") {
                    MediaPickerView(
                        title: "Foto de perfil para destacar tu negocio en Explorar:",
                        mediaURLString: $logoURLText,
                        selectedImageData: $selectedImageData
                    )
                }

                Section("Atención & Redes Sociales") {
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
                }

                Section("Configuración de Domicilio") {
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
                }

                Section("Etiquetas / Palabras Clave de Búsqueda") {
                    HStack {
                        TextField("Nueva etiqueta (ej. Postres)", text: $tagInput)
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
            }
            .navigationTitle("Configuración Comercial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveChanges()
                        dismiss()
                    }
                    .font(.headline)
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

    private func saveChanges() {
        store.updateBusinessContact(
            businessID: business.id,
            logoURL: logoURLText,
            whatsappNumber: whatsappNumber.isEmpty ? nil : whatsappNumber,
            instagramHandle: instagramHandle.isEmpty ? nil : instagramHandle,
            tags: tags
        )
    }
}
