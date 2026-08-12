import Foundation
import Observation

@MainActor
@Observable
final class MarketplaceStore {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private let repository: any MarketplaceRepository

    var loadState: LoadState = .idle
    var towns: [Town] = []
    var businesses: [Business] = []
    var requests: [LocalRequest] = []
    var activity: [ActivityItem] = []
    var news: [CommunityNews] = []
    var spots: [TownSpot] = []
    var selectedTownID: Town.ID?
    var selectedCategory: BusinessCategory?
    var searchText = ""

    init(repository: any MarketplaceRepository) {
        self.repository = repository
    }

    var selectedTown: Town? {
        towns.first { $0.id == selectedTownID } ?? towns.first
    }

    var filteredBusinesses: [Business] {
        guard let townID = selectedTown?.id else { return [] }
        return businesses.filter { business in
            let matchesTown = business.townID == townID
            let matchesCategory = selectedCategory == nil || business.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                business.name.localizedCaseInsensitiveContains(searchText) ||
                business.summary.localizedCaseInsensitiveContains(searchText) ||
                business.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            return matchesTown && matchesCategory && matchesSearch
        }
    }

    var townRequests: [LocalRequest] {
        guard let townID = selectedTown?.id else { return [] }
        return requests
            .filter { $0.townID == townID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var townNews: [CommunityNews] {
        guard let townID = selectedTown?.id else { return [] }
        return news
            .filter { $0.townID == townID || $0.isRegional }
            .sorted {
                if $0.urgency == .urgent, $1.urgency != .urgent { return true }
                if $0.urgency != .urgent, $1.urgency == .urgent { return false }
                return $0.createdAt > $1.createdAt
            }
    }

    var townSpots: [TownSpot] {
        guard let townID = selectedTown?.id else { return [] }
        return spots.filter { $0.townID == townID }
    }

    func load() async {
        guard loadState == .idle else { return }
        loadState = .loading
        do {
            let snapshot = try await repository.loadMarketplace()
            towns = snapshot.towns
            businesses = snapshot.businesses
            requests = snapshot.requests
            activity = snapshot.activity.sorted { $0.date > $1.date }
            news = snapshot.news
            spots = snapshot.spots
            selectedTownID = selectedTownID ?? towns.first?.id
            loadState = .loaded
        } catch {
            loadState = .failed("No pudimos cargar el pueblo. Revisa tu conexión.")
        }
    }

    func retry() async {
        loadState = .idle
        await load()
    }

    func selectTown(_ town: Town) {
        selectedTownID = town.id
        selectedCategory = nil
        searchText = ""
    }

    func publish(_ draft: RequestDraft) {
        guard draft.isValid, let townID = selectedTown?.id else { return }
        let request = LocalRequest(
            id: UUID(), townID: townID, author: "Tú",
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: draft.detail.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category, area: draft.area,
            createdAt: .now, budget: draft.budget, offerCount: 0,
            status: .published, isMine: true
        )
        requests.insert(request, at: 0)
        activity.insert(
            ActivityItem(
                id: UUID(), title: request.title,
                subtitle: "Tu solicitud ya está visible en \(selectedTown?.name ?? "el pueblo")",
                date: .now, symbol: request.category.symbol, status: .published
            ),
            at: 0
        )
    }

    func publishNews(_ draft: NewsDraft, author: String) {
        guard draft.isValid, let townID = selectedTown?.id else { return }
        news.insert(
            CommunityNews(
                id: UUID(), townID: townID, author: author,
                title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
                body: draft.body.trimmingCharacters(in: .whitespacesAndNewlines),
                category: draft.category, urgency: draft.urgency,
                location: draft.location.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: .now,
                sourceNote: draft.sourceNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : draft.sourceNote.trimmingCharacters(in: .whitespacesAndNewlines),
                verification: .unverified, confirmationCount: 0, didConfirm: false
            ),
            at: 0
        )
    }

    func replaceNews(for townID: Town.ID, with remoteNews: [CommunityNews]) {
        news.removeAll { $0.townID == townID }
        news.append(contentsOf: remoteNews)
    }

    func upsertNews(_ item: CommunityNews) {
        if let index = news.firstIndex(where: { $0.id == item.id }) {
            news[index] = item
        } else {
            news.insert(item, at: 0)
        }
    }

    func confirmNews(id: CommunityNews.ID) {
        guard let index = news.firstIndex(where: { $0.id == id }), !news[index].didConfirm else { return }
        news[index].didConfirm = true
        news[index].confirmationCount += 1
        if news[index].verification == .unverified, news[index].confirmationCount >= 3 {
            news[index].verification = .communityConfirmed
        }
    }

    // MARK: - Gestor de Comercio y Estantería (Mi Negocio)

    private var myBusinessID: UUID?

    var myBusiness: Business? {
        if let id = myBusinessID {
            return businesses.first { $0.id == id }
        }
        return nil
    }

    func createOrUpdateMyBusiness(
        name: String,
        category: BusinessCategory,
        summary: String,
        deliveryPrice: Int,
        etaMinutes: Int,
        symbol: String,
        colorName: String
    ) {
        guard let townID = selectedTown?.id else { return }
        let currentProducts = myBusiness?.products ?? []
        let id = myBusinessID ?? UUID()
        myBusinessID = id

        let updatedBusiness = Business(
            id: id,
            townID: townID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            etaMinutes: etaMinutes,
            deliveryPrice: deliveryPrice,
            rating: 5.0,
            reviewCount: 1,
            isOpen: true,
            symbol: symbol,
            colorName: colorName,
            products: currentProducts
        )

        if let index = businesses.firstIndex(where: { $0.id == id }) {
            businesses[index] = updatedBusiness
        } else {
            businesses.insert(updatedBusiness, at: 0)
        }
    }

    func addProduct(to businessID: UUID, product: Product) {
        guard let bIndex = businesses.firstIndex(where: { $0.id == businessID }) else { return }
        var updatedProducts = businesses[bIndex].products
        updatedProducts.append(product)
        businesses[bIndex] = rebuildBusiness(businesses[bIndex], products: updatedProducts)
    }

    func addProduct(to businessID: UUID, name: String, detail: String, price: Int) {
        let newProduct = Product(
            id: UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            detail: detail.trimmingCharacters(in: .whitespacesAndNewlines),
            price: price
        )
        addProduct(to: businessID, product: newProduct)
    }

    func updateProduct(in businessID: UUID, product: Product) {
        guard let bIndex = businesses.firstIndex(where: { $0.id == businessID }) else { return }
        var updatedProducts = businesses[bIndex].products
        if let pIndex = updatedProducts.firstIndex(where: { $0.id == product.id }) {
            updatedProducts[pIndex] = product
            businesses[bIndex] = rebuildBusiness(businesses[bIndex], products: updatedProducts)
        }
    }

    func deleteProduct(from businessID: UUID, productID: UUID) {
        guard let bIndex = businesses.firstIndex(where: { $0.id == businessID }) else { return }
        var updatedProducts = businesses[bIndex].products
        updatedProducts.removeAll { $0.id == productID }
        businesses[bIndex] = rebuildBusiness(businesses[bIndex], products: updatedProducts)
    }

    func bulkImportProducts(to businessID: UUID, products: [Product]) {
        guard let bIndex = businesses.firstIndex(where: { $0.id == businessID }) else { return }
        var updatedProducts = businesses[bIndex].products
        updatedProducts.append(contentsOf: products)
        businesses[bIndex] = rebuildBusiness(businesses[bIndex], products: updatedProducts)
    }

    private func rebuildBusiness(_ b: Business, products: [Product]) -> Business {
        Business(
            id: b.id, townID: b.townID, name: b.name, category: b.category,
            summary: b.summary, etaMinutes: b.etaMinutes, deliveryPrice: b.deliveryPrice,
            rating: b.rating, reviewCount: b.reviewCount, isOpen: b.isOpen,
            symbol: b.symbol, colorName: b.colorName, products: products,
            tags: b.tags, whatsappNumber: b.whatsappNumber, instagramHandle: b.instagramHandle, ownerID: b.ownerID
        )
    }

    func createBusiness(name: String, category: BusinessCategory, summary: String, tags: [String], whatsappNumber: String?, instagramHandle: String?, deliveryPrice: Int, etaMinutes: Int, ownerID: UUID?) -> Business? {
        guard let townID = selectedTown?.id else { return nil }
        let newBusiness = Business(
            id: UUID(),
            townID: townID,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
            etaMinutes: etaMinutes,
            deliveryPrice: deliveryPrice,
            rating: 5.0,
            reviewCount: 1,
            isOpen: true,
            symbol: category.symbol,
            colorName: "coral",
            products: [],
            tags: tags,
            whatsappNumber: whatsappNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
            instagramHandle: instagramHandle?.trimmingCharacters(in: .whitespacesAndNewlines),
            ownerID: ownerID
        )
        businesses.insert(newBusiness, at: 0)
        return newBusiness
    }

    func updateBusinessContact(businessID: UUID, whatsappNumber: String?, instagramHandle: String?, tags: [String]) {
        guard let index = businesses.firstIndex(where: { $0.id == businessID }) else { return }
        let b = businesses[index]
        businesses[index] = Business(
            id: b.id, townID: b.townID, name: b.name, category: b.category,
            summary: b.summary, etaMinutes: b.etaMinutes, deliveryPrice: b.deliveryPrice,
            rating: b.rating, reviewCount: b.reviewCount, isOpen: b.isOpen,
            symbol: b.symbol, colorName: b.colorName, products: b.products,
            tags: tags, whatsappNumber: whatsappNumber, instagramHandle: instagramHandle, ownerID: b.ownerID
        )
    }

    func publishSpot(name: String, description: String, category: SpotCategory, locationNote: String, author: String) {
        guard let townID = selectedTown?.id else { return }
        let newSpot = TownSpot(
            id: UUID(),
            townID: townID,
            author: author,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            locationNote: locationNote.trimmingCharacters(in: .whitespacesAndNewlines),
            photoSymbol: category.symbol,
            likesCount: 1,
            isLiked: true
        )
        spots.insert(newSpot, at: 0)
    }

    func toggleSpotLike(id: UUID) {
        guard let index = spots.firstIndex(where: { $0.id == id }) else { return }
        spots[index].isLiked.toggle()
        spots[index].likesCount += spots[index].isLiked ? 1 : -1
    }
}
