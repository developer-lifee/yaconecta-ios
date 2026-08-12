import Foundation

struct MarketplaceSnapshot: Sendable {
    let towns: [Town]
    let businesses: [Business]
    let requests: [LocalRequest]
    let activity: [ActivityItem]
    let news: [CommunityNews]
    let spots: [TownSpot]
}

protocol MarketplaceRepository: Sendable {
    func loadMarketplace() async throws -> MarketplaceSnapshot
}

struct DemoMarketplaceRepository: MarketplaceRepository {
    func loadMarketplace() async throws -> MarketplaceSnapshot {
        try await Task.sleep(for: .milliseconds(280))
        return DemoData.snapshot
    }
}

enum DemoData {
    static let cubarral = Town(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        name: "San Luis de Cubarral",
        region: "Meta",
        activeBusinesses: 45
    )
    static let elDorado = Town(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        name: "El Dorado",
        region: "Meta",
        activeBusinesses: 32
    )
    static let guamal = Town(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
        name: "Guamal",
        region: "Meta",
        activeBusinesses: 58
    )

    static let snapshot = MarketplaceSnapshot(
        towns: [cubarral, elDorado, guamal],
        businesses: [
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000005")!, townID: cubarral.id,
                name: "Dulcería La Granja", category: .food,
                summary: "Dulces típicos, golosinas, chocolates, galletas y regalitos", etaMinutes: 15, deliveryPrice: 3_000,
                rating: 4.9, reviewCount: 62, isOpen: true, symbol: "gift.fill", colorName: "coral",
                products: [
                    Product(id: UUID(), name: "Arequipe Llanero 250g", detail: "Arequipe de leche pura de vaca artesanal", price: 12_000),
                    Product(id: UUID(), name: "Combo Dulces Tradicionales", detail: "Cocadas, panelitas y cortados de leche", price: 16_000),
                    Product(id: UUID(), name: "Caja de Chocolates Surtidos", detail: "Para regalo de cumpleaños o aniversario", price: 25_000)
                ],
                tags: ["Dulcería", "Golosinas", "Postres", "Regalos"],
                whatsappNumber: "573101234567",
                instagramHandle: "@dulceria_cubarral"
            ),
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!, townID: cubarral.id,
                name: "Sazón Llanera Don Pedro", category: .food,
                summary: "Almuerzos caseros, carne a la llanera y sancocho de gallina", etaMinutes: 25, deliveryPrice: 4_000,
                rating: 4.9, reviewCount: 94, isOpen: true, symbol: "takeoutbag.and.cup.and.straw.fill", colorName: "coral",
                products: [
                    Product(id: UUID(), name: "Almuerzo del día", detail: "Sopa de plátano, principio, proteína y jugo", price: 18_000),
                    Product(id: UUID(), name: "Plato de Mamona", detail: "Carne a la perra/llanera con yuca y plátano", price: 28_000)
                ],
                tags: ["Restaurante", "Almuerzos", "Mamona"],
                whatsappNumber: "573129876543",
                instagramHandle: "@sazon_donpedro"
            ),
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!, townID: cubarral.id,
                name: "Droguería El Ariari", category: .pharmacy,
                summary: "Medicamentos, primeros auxilios y cuidado personal", etaMinutes: 15, deliveryPrice: 3_000,
                rating: 4.8, reviewCount: 53, isOpen: true, symbol: "cross.case.fill", colorName: "moss",
                products: [
                    Product(id: UUID(), name: "Consulta por disponibilidad", detail: "Escríbenos el medicamento que buscas", price: 0)
                ],
                tags: ["Droguería", "Medicamentos", "Salud"],
                whatsappNumber: "573204567890"
            ),
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!, townID: cubarral.id,
                name: "Ferretería y Remate El Cubarral", category: .services,
                summary: "Herramientas, cemento, tanques de agua y artículos para finca", etaMinutes: 30, deliveryPrice: 5_000,
                rating: 4.9, reviewCount: 118, isOpen: true, symbol: "wrench.and.screwdriver.fill", colorName: "sun",
                products: [
                    Product(id: UUID(), name: "Tanque plástico 500L", detail: "Tanque azul reforzado con tapa para reserva", price: 240_000),
                    Product(id: UUID(), name: "Bulto de cemento 50kg", detail: "Cemento gris estructurado para obra", price: 32_000)
                ],
                tags: ["Ferretería", "Remate", "Herramientas", "Finca"],
                whatsappNumber: "573156789012"
            ),
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!, townID: cubarral.id,
                name: "Expresos del Ariari", category: .transport,
                summary: "Mototaxis y camperos a veredas y municipios vecinos", etaMinutes: 10, deliveryPrice: 6_000,
                rating: 4.9, reviewCount: 140, isOpen: true, symbol: "motorcycle.fill", colorName: "sky",
                products: [
                    Product(id: UUID(), name: "Carrera urbana Cubarral", detail: "Desplazamiento dentro del casco urbano", price: 6_000),
                    Product(id: UUID(), name: "Expreso Cubarral - El Dorado", detail: "Recorrido en moto o campero", price: 18_000)
                ],
                tags: ["Expresos", "Mototaxi", "Transporte"],
                whatsappNumber: "573187654321"
            ),
            Business(
                id: UUID(), townID: guamal.id, name: "Parador Turístico Guamal", category: .food,
                summary: "Pan de arroz, masato y parrillada llanera", etaMinutes: 20, deliveryPrice: 4_500,
                rating: 4.8, reviewCount: 82, isOpen: true, symbol: "leaf.fill", colorName: "sky", products: [],
                tags: ["Pan de Arroz", "Parador", "Masato"],
                whatsappNumber: "573111112233"
            )
        ],
        requests: [
            LocalRequest(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!, townID: cubarral.id,
                author: "María P.", title: "Necesito mercado hasta la vereda Central", detail: "Recoger compra en la galería y llevar a la vereda Central.",
                category: .errand, area: "Vereda Central", createdAt: .now.addingTimeInterval(-720), budget: 18_000,
                offerCount: 3, status: .published, isMine: false
            ),
            LocalRequest(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!, townID: cubarral.id,
                author: "Carlos R.", title: "Busco motobomba de agua usada o nueva", detail: "Para extracción en finca cerca al río Ariari. Escribir disponibilidad.",
                category: .wanted, area: "Centro Cubarral", createdAt: .now.addingTimeInterval(-1_900), budget: nil,
                offerCount: 2, status: .published, isMine: false
            ),
            LocalRequest(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000003")!, townID: cubarral.id,
                author: "Tú", title: "Expreso hacia Guamal", detail: "Salida para 2 personas con maletas medianas a las 4:00 p. m.",
                category: .transport, area: "Plaza principal", createdAt: .now.addingTimeInterval(-3_400), budget: 25_000,
                offerCount: 1, status: .agreed, isMine: true
            )
        ],
        activity: [
            ActivityItem(id: UUID(), title: "Expreso hacia Guamal", subtitle: "Don Marcos aceptó por $25.000", date: .now.addingTimeInterval(-600), symbol: "car.fill", status: .agreed),
            ActivityItem(id: UUID(), title: "Mamona de Sazón Llanera", subtitle: "Entregada por Camilo", date: .now.addingTimeInterval(-86_400), symbol: "checkmark.circle.fill", status: .completed)
        ],
        news: [
            CommunityNews(
                id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!, townID: cubarral.id,
                author: "Defensa Civil Cubarral", title: "Estado del caudal en el río Ariari",
                body: "Se reporta aumento preventivo en el nivel del río por lluvias en la cordillera. Se recomienda a pescadores y turistas mantener precaución en los balnearios.",
                category: .emergency, urgency: .urgent, location: "Río Ariari y Balnearios",
                createdAt: .now.addingTimeInterval(-1_140), sourceNote: "Reporte oficial Defensa Civil",
                verification: .verified, confirmationCount: 24, didConfirm: false
            ),
            CommunityNews(
                id: UUID(uuidString: "40000000-0000-0000-0000-000000000002")!, townID: cubarral.id,
                author: "Laura M.", title: "Mantenimiento eléctrico en el centro de Cubarral",
                body: "ElectroMeta realizará cortes programados mañana entre las 8:00 a. m. y 12:00 m. para adecuación de transformadores.",
                category: .publicService, urgency: .important, location: "Casco Urbano",
                createdAt: .now.addingTimeInterval(-3_200), sourceNote: "Aviso de la empresa de energía",
                verification: .communityConfirmed, confirmationCount: 14, didConfirm: false
            ),
            CommunityNews(
                id: UUID(), townID: elDorado.id, author: "Alcaldía El Dorado",
                title: "Mercado campesino este fin de semana",
                body: "Invitación a todos los productores del Ariari a exponer frutas, cacao y plátano en el parque principal.",
                category: .community, urgency: .informative, location: "Parque principal El Dorado",
                createdAt: .now.addingTimeInterval(-600), sourceNote: "Alcaldía municipal",
                verification: .verified, confirmationCount: 19, didConfirm: false
            )
        ],
        spots: [
            TownSpot(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!, townID: cubarral.id,
                author: "Esteban A.", name: "Balneario y Río Ariari",
                description: "Aguas cristalinas refrescantes al pie de la cordillera. El sitio perfecto para sancocho de olla y fotos al atardecer.",
                category: .nature, locationNote: "A 5 minutos del casco urbano de Cubarral",
                photoSymbol: "water.waves",
                photoURL: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800",
                photos: ["https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800"],
                reviews: [
                    SpotReview(id: UUID(), author: "Camilo R.", comment: "El agua es súper limpia y fresca. Recomendado ir en la mañana.", rating: 5, photoURL: nil, createdAt: Date().addingTimeInterval(-86400)),
                    SpotReview(id: UUID(), author: "Maria P.", comment: "Excelente lugar para venir en familia el fin de semana.", rating: 5, photoURL: nil, createdAt: Date().addingTimeInterval(-172800))
                ],
                likesCount: 68, isLiked: false
            ),
            TownSpot(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000002")!, townID: cubarral.id,
                author: "Andrea V.", name: "Mirador del Ariari y Cordillera",
                description: "Una panorámica impresionante donde se juntan los llanos orientales con la cordillera. Increíble para tomar fotos.",
                category: .photo, locationNote: "Vía a la vereda la Libertad",
                photoSymbol: "camera.fill",
                photoURL: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800",
                photos: ["https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800"],
                reviews: [
                    SpotReview(id: UUID(), author: "Felipe T.", comment: "La mejor vista del llano y la cordillera. Para atardeceres es increíble.", rating: 5, photoURL: nil, createdAt: Date().addingTimeInterval(-43200))
                ],
                likesCount: 54, isLiked: false
            ),
            TownSpot(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000003")!, townID: cubarral.id,
                author: "Don Gonzalo", name: "Parche del Pan de Arroz y Masato",
                description: "Negocio tradicional de más de 30 años. El masato más frío y el verdadero pan de arroz llanero.",
                category: .chill, locationNote: "Salida hacia Guamal",
                photoSymbol: "cup.and.saucer.fill",
                photoURL: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800",
                photos: ["https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800"],
                reviews: [],
                likesCount: 47, isLiked: false
            )
        ]
    )
}
