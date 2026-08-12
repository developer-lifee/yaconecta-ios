import SwiftUI

struct BusinessDetailView: View {
    @Environment(\.openURL) private var openURL
    let business: Business
    @State private var showContactConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                contactChannels
                tagsView
                details
                products
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(business.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .alert("Pedido iniciado", isPresented: $showContactConfirmation) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Abrimos canal directo con \(business.name) para coordinar tu entrega en Cubarral.")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: business.symbol)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(AppTheme.coral)
                .frame(width: 90, height: 90)
                .background(AppTheme.sand, in: RoundedRectangle(cornerRadius: 26))
            Text(business.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(business.summary)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 18) {
                Label("\(business.rating.formatted(.number.precision(.fractionLength(1)))) (\(business.reviewCount))", systemImage: "star.fill")
                Label("\(business.etaMinutes) min", systemImage: "clock.fill")
            }
            .font(.subheadline.bold())
            .foregroundStyle(AppTheme.moss)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .cardSurface()
    }

    private var contactChannels: some View {
        HStack(spacing: 12) {
            if let whatsapp = business.whatsappNumber, !whatsapp.isEmpty {
                Button {
                    openWhatsApp(number: whatsapp)
                } label: {
                    Label("WhatsApp Directo", systemImage: "message.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
                }
            }

            if let insta = business.instagramHandle, !insta.isEmpty {
                Button {
                    let clean = insta.replacingOccurrences(of: "@", with: "")
                    if let url = URL(string: "https://instagram.com/\(clean)") {
                        openURL(url)
                    }
                } label: {
                    Label("Instagram", systemImage: "camera.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.purple, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var tagsView: some View {
        Group {
            if !business.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(business.tags, id: \.self) { tag in
                            Label(tag, systemImage: "tag.fill")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .foregroundStyle(AppTheme.coral)
                                .background(AppTheme.coral.opacity(0.12), in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private var details: some View {
        HStack {
            Label(business.isOpen ? "Abierto ahora" : "Cerrado", systemImage: "door.left.hand.open")
            Spacer()
            Text("Domicilio \(business.deliveryPrice.colombianCurrency)")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(AppTheme.moss)
        .padding(16)
        .cardSurface()
    }

    private var products: some View {
        VStack(spacing: 12) {
            SectionHeading(title: "Productos y catálogo")
            if business.products.isEmpty {
                Text("Escríbenos por WhatsApp o por la app para consultar disponibilidad del producto que buscas.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardSurface()
            } else {
                ForEach(business.products) { product in
                    HStack(spacing: 14) {
                        if let urlString = product.imageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    Image(systemName: "photo")
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name).font(.headline)
                            if !product.detail.isEmpty {
                                Text(product.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(product.price == 0 ? "Acordar" : product.price.colombianCurrency)
                            .font(.subheadline.bold())
                            .foregroundStyle(AppTheme.coral)
                    }
                    .padding(16)
                    .cardSurface()
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            if let whatsapp = business.whatsappNumber, !whatsapp.isEmpty {
                Button {
                    openWhatsApp(number: whatsapp)
                } label: {
                    Label("Pedir por WhatsApp", systemImage: "phone.bubble.left.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Button {
                    showContactConfirmation = true
                } label: {
                    Label("Iniciar pedido por App", systemImage: "bubble.left.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func openWhatsApp(number: String) {
        let cleanNumber = number.filter(\.isNumber)
        let message = "Hola \(business.name)! Te escribo desde la app YaConecta Cubarral. Me gustaría pedir información o hacer una compra."
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let whatsappURLString = "https://wa.me/\(cleanNumber)?text=\(encodedMessage)"
        if let url = URL(string: whatsappURLString) {
            openURL(url)
        }
    }
}
