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
    @Environment(MarketplaceStore.self) private var store
    let request: LocalRequest

    @State private var isPresentingMakeOffer = false

    private var currentRequest: LocalRequest {
        store.requests.first(where: { $0.id == request.id }) ?? request
    }

    private var offers: [RequestOffer] {
        store.offersForRequest(request.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label(currentRequest.category.rawValue, systemImage: currentRequest.category.symbol)
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.coral)
                    Spacer()
                    StatusPill(status: currentRequest.status)
                }
                Text(currentRequest.title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ink)
                Text(currentRequest.detail)
                    .font(.body)
                Divider()
                Label(currentRequest.area, systemImage: "mappin.and.ellipse")
                Label("Publicado por \(currentRequest.author)", systemImage: "person.crop.circle")
                if let budget = currentRequest.budget {
                    Label("Presupuesto base: \(budget.colombianCurrency)", systemImage: "banknote")
                        .font(.subheadline.bold())
                        .foregroundStyle(AppTheme.moss)
                }

                Divider()

                // Sección de Contraofertas estilo inDriver
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Propuestas & Contraofertas (\(offers.count))")
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)
                            Text("Vecinos y comerciantes negociando el encargo")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !currentRequest.isMine {
                            Button("Negociar Tarifa") {
                                isPresentingMakeOffer = true
                            }
                            .font(.caption.bold())
                            .buttonStyle(.borderedProminent)
                            .tint(AppTheme.coral)
                        }
                    }

                    if offers.isEmpty {
                        Text("Aún no hay propuestas enviadas para este encargo. ¡Sé el primero en proponer tu tarifa!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(14)
                            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    } else {
                        VStack(spacing: 10) {
                            ForEach(offers) { offer in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(offer.offererName)
                                                .font(.subheadline.bold())
                                            Text(offer.createdAt, style: .relative)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(offer.proposedPrice.colombianCurrency)
                                                .font(.headline.bold())
                                                .foregroundStyle(AppTheme.moss)
                                            Text(offer.status.rawValue)
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(
                                                    offer.status == .accepted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15),
                                                    in: Capsule()
                                                )
                                                .foregroundStyle(offer.status == .accepted ? .green : .orange)
                                        }
                                    }

                                    if let note = offer.note, !note.isEmpty {
                                        Text("“\(note)”")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .italic()
                                    }

                                    // Si es el dueño del encargo y la oferta está pendiente:
                                    if currentRequest.isMine, offer.status == .pending {
                                        HStack(spacing: 10) {
                                            Button("Aceptar Propuesta (\(offer.proposedPrice.colombianCurrency))") {
                                                store.acceptOffer(offerID: offer.id)
                                            }
                                            .font(.caption.bold())
                                            .buttonStyle(.borderedProminent)
                                            .tint(AppTheme.moss)

                                            if let phone = offer.offererPhone, !phone.isEmpty {
                                                Link(destination: URL(string: "https://wa.me/\(phone)?text=Hola%20\(offer.offererName),%20acepto%20tu%20propuesta%20de%20\(offer.proposedPrice.colombianCurrency)%20para%20\(currentRequest.title)")!) {
                                                    Label("WhatsApp", systemImage: "message.fill")
                                                        .font(.caption.bold())
                                                        .foregroundStyle(.green)
                                                }
                                            }
                                        }
                                        .padding(.top, 4)
                                    }
                                }
                                .padding(14)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .cardSurface()
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Detalle del Encargo")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if !currentRequest.isMine {
                Button("Ofrecer / Negociar Tarifa") {
                    isPresentingMakeOffer = true
                }
                .font(.headline)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.coral)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(.bar)
            }
        }
        .sheet(isPresented: $isPresentingMakeOffer) {
            MakeOfferSheet(request: currentRequest)
        }
    }
}
