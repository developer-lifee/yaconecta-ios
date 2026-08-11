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
    static let guaduas = Town(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        name: "Guaduas",
        region: "Cundinamarca",
        activeBusinesses: 38
    )
    static let honda = Town(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
        name: "Honda",
        region: "Tolima",
        activeBusinesses: 52
    )
    static let jardin = Town(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
        name: "Jardín",
        region: "Antioquia",
        activeBusinesses: 44
    )

    static let snapshot = MarketplaceSnapshot(
        towns: [guaduas, honda, jardin],
        businesses: [
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000001")!, townID: guaduas.id,
                name: "La Esquina de Omaira", category: .food,
                summary: "Almuerzos caseros y corrientazos", etaMinutes: 25, deliveryPrice: 4_000,
                rating: 4.9, reviewCount: 86, isOpen: true, symbol: "takeoutbag.and.cup.and.straw.fill", colorName: "coral",
                products: [
                    Product(id: UUID(), name: "Almuerzo del día", detail: "Sopa, principio, proteína y jugo", price: 18_000),
                    Product(id: UUID(), name: "Bandeja campesina", detail: "Fríjol, arroz, carne molida y aguacate", price: 24_000)
                ]
            ),
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000002")!, townID: guaduas.id,
                name: "Droguería La 13", category: .pharmacy,
                summary: "Medicamentos y cuidado personal", etaMinutes: 18, deliveryPrice: 3_000,
                rating: 4.8, reviewCount: 41, isOpen: true, symbol: "cross.case.fill", colorName: "moss",
                products: [
                    Product(id: UUID(), name: "Consulta por disponibilidad", detail: "Escríbenos el nombre del producto", price: 0)
                ]
            ),
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000003")!, townID: guaduas.id,
                name: "Mercadito Don Rafa", category: .market,
                summary: "Mercado, frutas y productos de aseo", etaMinutes: 32, deliveryPrice: 5_000,
                rating: 4.7, reviewCount: 59, isOpen: true, symbol: "basket.fill", colorName: "sun",
                products: [
                    Product(id: UUID(), name: "Canasta básica", detail: "Arroz, aceite, huevos, panela y leche", price: 48_000),
                    Product(id: UUID(), name: "Frutas de la semana", detail: "Selección de frutas frescas", price: 28_000)
                ]
            ),
            Business(
                id: UUID(uuidString: "20000000-0000-0000-0000-000000000004")!, townID: guaduas.id,
                name: "Expresos El Mono", category: .transport,
                summary: "Moto y carro, casco adicional incluido", etaMinutes: 12, deliveryPrice: 6_000,
                rating: 4.9, reviewCount: 112, isOpen: true, symbol: "motorcycle.fill", colorName: "sky",
                products: [
                    Product(id: UUID(), name: "Carrera urbana", detail: "Precio base dentro del casco urbano", price: 6_000),
                    Product(id: UUID(), name: "Viaje a vereda", detail: "Acordamos el precio según el recorrido", price: 0)
                ]
            ),
            Business(
                id: UUID(), townID: honda.id, name: "Sazón del Puerto", category: .food,
                summary: "Comida tradicional del Magdalena", etaMinutes: 28, deliveryPrice: 4_500,
                rating: 4.8, reviewCount: 74, isOpen: true, symbol: "fish.fill", colorName: "sky", products: []
            )
        ],
        requests: [
            LocalRequest(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000001")!, townID: guaduas.id,
                author: "María P.", title: "Necesito mercado hasta la vereda", detail: "Recoger una compra en Don Rafa y llevarla a Cucharal.",
                category: .errand, area: "Vereda Cucharal", createdAt: .now.addingTimeInterval(-720), budget: 18_000,
                offerCount: 3, status: .published, isMine: false
            ),
            LocalRequest(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000002")!, townID: guaduas.id,
                author: "Carlos R.", title: "Busco electricista para hoy", detail: "Un tomacorriente está haciendo corto. Casa en el centro.",
                category: .service, area: "Centro", createdAt: .now.addingTimeInterval(-1_900), budget: nil,
                offerCount: 2, status: .published, isMine: false
            ),
            LocalRequest(
                id: UUID(uuidString: "30000000-0000-0000-0000-000000000003")!, townID: guaduas.id,
                author: "Tú", title: "Expreso hacia la terminal", detail: "Una persona y una maleta pequeña para las 4:30 p. m.",
                category: .transport, area: "Plaza principal", createdAt: .now.addingTimeInterval(-3_400), budget: 9_000,
                offerCount: 1, status: .agreed, isMine: true
            )
        ],
        activity: [
            ActivityItem(id: UUID(), title: "Expreso hacia la terminal", subtitle: "Julián aceptó por $9.000", date: .now.addingTimeInterval(-600), symbol: "car.fill", status: .agreed),
            ActivityItem(id: UUID(), title: "Almuerzo de La Esquina", subtitle: "Entregado por Mateo", date: .now.addingTimeInterval(-86_400), symbol: "checkmark.circle.fill", status: .completed)
        ],
        news: [
            CommunityNews(
                id: UUID(uuidString: "40000000-0000-0000-0000-000000000001")!, townID: guaduas.id,
                author: "Defensa Civil Guaduas", title: "Paso restringido en la vía a Caparrapí",
                body: "Un deslizamiento cubre medio carril en el sector Alto de la Mona. Hay paso controlado y se recomienda evitar la vía durante la lluvia.",
                category: .roads, urgency: .urgent, location: "Alto de la Mona",
                createdAt: .now.addingTimeInterval(-1_140), sourceNote: "Reporte de Defensa Civil",
                verification: .verified, confirmationCount: 18, didConfirm: false
            ),
            CommunityNews(
                id: UUID(uuidString: "40000000-0000-0000-0000-000000000002")!, townID: guaduas.id,
                author: "Laura M.", title: "Sin servicio de agua en El Carmelo",
                body: "Vecinos reportan que el agua no llega desde esta mañana. La empresa aún no informa la hora estimada de regreso.",
                category: .publicService, urgency: .important, location: "Barrio El Carmelo",
                createdAt: .now.addingTimeInterval(-3_200), sourceNote: "Observado por residentes",
                verification: .communityConfirmed, confirmationCount: 9, didConfirm: false
            ),
            CommunityNews(
                id: UUID(uuidString: "40000000-0000-0000-0000-000000000003")!, townID: guaduas.id,
                author: "Parroquia San Miguel", title: "Acompañamiento a la familia Rodríguez",
                body: "La comunidad acompaña a la familia Rodríguez en este momento difícil. La velación se realizará esta tarde en la sala comunal.",
                category: .mourning, urgency: .informative, location: "Sala comunal del centro",
                createdAt: .now.addingTimeInterval(-8_400), sourceNote: "Información compartida por la familia",
                verification: .verified, confirmationCount: 6, didConfirm: false
            ),
            CommunityNews(
                id: UUID(), townID: honda.id, author: "Bomberos Honda",
                title: "Árbol caído cerca del puente Navarro",
                body: "La vía presenta paso reducido mientras el equipo retira un árbol caído. Conduzca con precaución.",
                category: .roads, urgency: .urgent, location: "Acceso al puente Navarro",
                createdAt: .now.addingTimeInterval(-600), sourceNote: "Bomberos voluntarios",
                verification: .verified, confirmationCount: 12, didConfirm: false
            )
        ],
        spots: [
            TownSpot(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000001")!, townID: guaduas.id,
                author: "Felipe M.", name: "Mirador de la Piedra Capira",
                description: "Una de las mejores vistas del valle del Magdalena. Ideal para ver el atardecer y tomar fotos panorámicas increibles.",
                category: .photo, locationNote: "Camino a la vereda La Capira (20 min en expreso)",
                photoSymbol: "mountain.2.fill", likesCount: 42, isLiked: false
            ),
            TownSpot(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000002")!, townID: guaduas.id,
                author: "Andrea V.", name: "Patio Imperial del Café",
                description: "Un rincón tranquilo con sombra de árboles centenarios. Sirven café de origen local y granizados deliciosos.",
                category: .chill, locationNote: "Calle Real, 2 cuadras arriba de la plaza",
                photoSymbol: "cup.and.saucer.fill", likesCount: 29, isLiked: false
            ),
            TownSpot(
                id: UUID(uuidString: "50000000-0000-0000-0000-000000000003")!, townID: guaduas.id,
                author: "Don Bernardo", name: "Puente Colonial de la Pola",
                description: "Lugar lleno de historia patria. Excelente iluminación nocturna para fotos y caminata tranquila.",
                category: .history, locationNote: "Borde del centro histórico",
                photoSymbol: "building.columns.fill", likesCount: 37, isLiked: false
            )
        ]
    )
}
