import SwiftUI

struct BusinessDetailView: View {
    let business: Business
    @State private var showContactConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                details
                products
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(business.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                showContactConfirmation = true
            } label: {
                Label("Iniciar pedido", systemImage: "bubble.left.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.bar)
            .accessibilityIdentifier("start-order-button")
        }
        .alert("Pedido iniciado", isPresented: $showContactConfirmation) {
            Button("Entendido", role: .cancel) {}
        } message: {
            Text("Abrimos un chat seguro con \(business.name). En la siguiente versión podrás completar el pedido aquí.")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: business.symbol)
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(AppTheme.coral)
                .frame(width: 100, height: 100)
                .background(AppTheme.sand, in: RoundedRectangle(cornerRadius: 28))
            Text(business.name)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(business.summary)
                .foregroundStyle(.secondary)
            HStack(spacing: 18) {
                Label("\(business.rating.formatted(.number.precision(.fractionLength(1)))) (\(business.reviewCount))", systemImage: "star.fill")
                Label("\(business.etaMinutes) min", systemImage: "clock.fill")
            }
            .font(.subheadline.bold())
            .foregroundStyle(AppTheme.moss)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .cardSurface()
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
            SectionHeading(title: "Productos y servicios")
            if business.products.isEmpty {
                Text("Pregunta por disponibilidad directamente al comercio.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .cardSurface()
            } else {
                ForEach(business.products) { product in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name).font(.headline)
                            Text(product.detail).font(.subheadline).foregroundStyle(.secondary)
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
}
