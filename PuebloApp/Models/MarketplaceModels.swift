import Foundation

struct Town: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let region: String
    let activeBusinesses: Int
}

enum BusinessCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case food = "Comida"
    case market = "Mercado"
    case pharmacy = "Farmacia"
    case transport = "Expresos"
    case services = "Servicios"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .food: "fork.knife"
        case .market: "basket.fill"
        case .pharmacy: "cross.case.fill"
        case .transport: "motorcycle.fill"
        case .services: "wrench.and.screwdriver.fill"
        }
    }
}

struct Business: Identifiable, Hashable, Sendable {
    let id: UUID
    let townID: UUID
    let name: String
    let category: BusinessCategory
    let summary: String
    let etaMinutes: Int
    let deliveryPrice: Int
    let rating: Double
    let reviewCount: Int
    let isOpen: Bool
    let symbol: String
    let colorName: String
    let products: [Product]
}

struct Product: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let detail: String
    let price: Int
}

enum RequestCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case delivery = "Domicilio"
    case transport = "Expreso"
    case errand = "Mandado"
    case service = "Servicio"
    case wanted = "Busco algo"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .delivery: "bag.fill"
        case .transport: "car.fill"
        case .errand: "figure.walk.motion"
        case .service: "hammer.fill"
        case .wanted: "magnifyingglass"
        }
    }
}

enum RequestStatus: String, Hashable, Sendable {
    case published = "Publicada"
    case agreed = "Acordada"
    case onTheWay = "En camino"
    case completed = "Completada"
}

struct LocalRequest: Identifiable, Hashable, Sendable {
    let id: UUID
    let townID: UUID
    let author: String
    let title: String
    let detail: String
    let category: RequestCategory
    let area: String
    let createdAt: Date
    let budget: Int?
    var offerCount: Int
    var status: RequestStatus
    let isMine: Bool
}

struct RequestDraft: Equatable, Sendable {
    var title = ""
    var detail = ""
    var category: RequestCategory = .delivery
    var area = "Centro"
    var budget: Int?

    var isValid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 5 &&
        detail.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
    }
}

struct ActivityItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String
    let date: Date
    let symbol: String
    let status: RequestStatus
}

enum NewsCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case roads = "Vías y transporte"
    case emergency = "Emergencia"
    case publicService = "Servicio público"
    case community = "Comunidad"
    case mourning = "Luto"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .roads: "road.lanes"
        case .emergency: "exclamationmark.triangle.fill"
        case .publicService: "bolt.trianglebadge.exclamationmark.fill"
        case .community: "person.3.fill"
        case .mourning: "heart.fill"
        }
    }
}

enum NewsUrgency: String, CaseIterable, Identifiable, Hashable, Sendable {
    case informative = "Informativa"
    case important = "Importante"
    case urgent = "Urgente"

    var id: String { rawValue }
}

enum VerificationStatus: String, Hashable, Sendable {
    case unverified = "Sin verificar"
    case communityConfirmed = "Confirmada por vecinos"
    case verified = "Verificada"
}

struct CommunityNews: Identifiable, Hashable, Sendable {
    let id: UUID
    let townID: UUID
    let author: String
    let title: String
    let body: String
    let category: NewsCategory
    let urgency: NewsUrgency
    let location: String
    let createdAt: Date
    let sourceNote: String?
    var verification: VerificationStatus
    var confirmationCount: Int
    var didConfirm: Bool
}

struct NewsDraft: Equatable, Sendable {
    var title = ""
    var body = ""
    var category: NewsCategory = .roads
    var urgency: NewsUrgency = .important
    var location = ""
    var sourceNote = ""
    var acceptsResponsibility = false

    var isValid: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 &&
        body.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20 &&
        location.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        acceptsResponsibility
    }
}

extension Int {
    var colombianCurrency: String {
        formatted(.currency(code: "COP").precision(.fractionLength(0)))
    }
}
