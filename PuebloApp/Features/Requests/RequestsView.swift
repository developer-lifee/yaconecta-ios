import SwiftUI

struct RequestsView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AppRouter.self) private var router
    @State private var scope: Scope = .nearby

    private enum Scope: String, CaseIterable, Identifiable {
        case nearby = "Cerca de mí"
        case mine = "Mis solicitudes"
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                Picker("Alcance", selection: $scope) {
                    ForEach(Scope.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                ForEach(visibleRequests) { request in
                    Button {
                        router.navigate(to: .request(request))
                    } label: {
                        RequestRow(request: request)
                    }
                    .buttonStyle(.plain)
                }

                if visibleRequests.isEmpty {
                    ContentUnavailableView(
                        "Todavía no hay solicitudes",
                        systemImage: "text.bubble",
                        description: Text("Sé la primera persona en publicar lo que necesita.")
                    )
                    .frame(minHeight: 320)
                }
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Solicitudes")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { TownButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.sheet = .createRequest
                } label: {
                    Label("Publicar", systemImage: "plus")
                }
                .accessibilityIdentifier("requests-create-button")
            }
        }
    }

    private var visibleRequests: [LocalRequest] {
        store.townRequests.filter { scope == .mine ? $0.isMine : !$0.isMine }
    }
}

struct RequestDetailView: View {
    let request: LocalRequest
    @State private var showOfferSent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label(request.category.rawValue, systemImage: request.category.symbol)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.coral)
                    Spacer()
                    StatusPill(status: request.status)
                }
                Text(request.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ink)
                Text(request.detail)
                    .font(.body)
                Divider()
                Label(request.area, systemImage: "mappin.and.ellipse")
                Label("Publicado por \(request.author)", systemImage: "person.crop.circle")
                if let budget = request.budget {
                    Label("Presupuesto: \(budget.colombianCurrency)", systemImage: "banknote")
                }
                Label("\(request.offerCount) propuestas recibidas", systemImage: "bubble.left.and.bubble.right")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .cardSurface()
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !request.isMine {
                Button("Enviar una propuesta") {
                    showOfferSent = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.bar)
            }
        }
        .alert("Propuesta enviada", isPresented: $showOfferSent) {
            Button("Listo", role: .cancel) {}
        } message: {
            Text("\(request.author) podrá verla y conversar contigo de forma privada.")
        }
    }
}
