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
    var requestOffers: [RequestOffer] = []
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
        guard !remoteNews.isEmpty else { return }
        for item in remoteNews {
            if let idx = news.firstIndex(where: { $0.id == item.id }) {
                news[idx] = item
            } else {
                news.append(item)
            }
        }
        news.sort { $0.createdAt > $1.createdAt }
    }

    func offersForRequest(_ requestID: UUID) -> [RequestOffer] {
        requestOffers
            .filter { $0.requestID == requestID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func submitCounterOffer(requestID: UUID, offererName: String, offererPhone: String?, price: Int, note: String?) {
        guard let index = requests.firstIndex(where: { $0.id == requestID }) else { return }
        
        let newOffer = RequestOffer(
            id: UUID(),
            requestID: requestID,
            offererName: offererName,
            offererPhone: offererPhone,
            proposedPrice: price,
            note: note,
            status: .pending,
            createdAt: Date()
        )
        
        requestOffers.insert(newOffer, at: 0)
        requests[index].offerCount += 1
        
        activity.insert(
            ActivityItem(
                id: UUID(),
                title: "Contraoferta enviada",
                subtitle: "\(requests[index].title) - \(price.colombianCurrency)",
                date: Date(),
                symbol: "banknote.fill",
                status: .agreed
            ),
            at: 0
        )
    }

    func acceptOffer(offerID: UUID) {
        guard let offerIdx = requestOffers.firstIndex(where: { $0.id == offerID }) else { return }
        requestOffers[offerIdx].status = .accepted
        
        let reqID = requestOffers[offerIdx].requestID
        if let reqIdx = requests.firstIndex(where: { $0.id == reqID }) {
            requests[reqIdx].status = .agreed
            
            activity.insert(
                ActivityItem(
                    id: UUID(),
                    title: "Trato Acordado",
                    subtitle: "\(requests[reqIdx].title) con \(requestOffers[offerIdx].offererName)",
                    date: Date(),
                    symbol: "hand.thumbsup.fill",
                    status: .agreed
                ),
                at: 0
            )
        }
    }

    func upsertNews(_ item: CommunityNews) {
        if let index = news.firstIndex(where: { $0.id == item.id }) {
            news[index] = item
        } else {
            news.insert(item, at: 0)
        }
    }

    func addNewsEvidence(newsID: UUID, evidence: NewsEvidence) {
        guard let index = news.firstIndex(where: { $0.id == newsID }) else { return }
        news[index].evidences.insert(evidence, at: 0)
        news[index].confirmationCount += 1
        if news[index].verification == .unverified, news[index].confirmationCount >= 3 {
            news[index].verification = .communityConfirmed
        }
        activity.insert(
            ActivityItem(
                id: UUID(),
                title: "Evidencia Aportada",
                subtitle: news[index].title,
                date: Date(),
                symbol: "camera.fill",
                status: .published
            ),
            at: 0
        )
    }

    func confirmNews(id: CommunityNews.ID) {
        guard let index = news.firstIndex(where: { $0.id == id }), !news[index].didConfirm else { return }
        news[index].didConfirm = true
        news[index].confirmationCount += 1
        if news[index].verification == .unverified, news[index].confirmationCount >= 3 {
            news[index].verification = .communityConfirmed
        }

        let activityItem = ActivityItem(
            id: UUID(),
            title: "Confirmación de Noticia Útil",
            subtitle: news[index].title,
            date: Date(),
            symbol: "checkmark.seal.fill",
            status: .completed
        )
        activity.insert(activityItem, at: 0)
    }

    // MARK: - Misiones del Pueblo y Nivel de Verificación
    var completedDealsCount: Int {
        activity.filter { $0.status == .completed }.count
    }

    var usefulConfirmationsCount: Int {
        news.filter { $0.didConfirm }.count
    }

    var userSpotsCount: Int {
        spots.filter { $0.isLiked || $0.author.contains("Esteban") }.count
    }

    var missionsCompletedCount: Int {
        (completedDealsCount > 0 ? 1 : 0) +
        (usefulConfirmationsCount > 0 ? 1 : 0) +
        (userSpotsCount > 0 ? 1 : 0)
    }

    var isAccountVerified: Bool {
        missionsCompletedCount >= 3
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
            tags: b.tags, whatsappNumber: b.whatsappNumber, instagramHandle: b.instagramHandle, ownerID: b.ownerID, logoURL: b.logoURL
        )
    }

    func createBusiness(name: String, category: BusinessCategory, summary: String, tags: [String], whatsappNumber: String?, instagramHandle: String?, deliveryPrice: Int, etaMinutes: Int, ownerID: UUID?, logoURL: String? = nil) -> Business? {
        guard let townID = selectedTown?.id else { return nil }
        let id = UUID()
        let cleanLogo = logoURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalLogo = (cleanLogo?.isEmpty ?? true) ? nil : cleanLogo

        let newBusiness = Business(
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
            symbol: category.symbol,
            colorName: "coral",
            products: [],
            tags: tags,
            whatsappNumber: whatsappNumber?.trimmingCharacters(in: .whitespacesAndNewlines),
            instagramHandle: instagramHandle?.trimmingCharacters(in: .whitespacesAndNewlines),
            ownerID: ownerID,
            logoURL: finalLogo
        )
        myBusinessID = id
        businesses.insert(newBusiness, at: 0)
        return newBusiness
    }

    func updateBusinessContact(businessID: UUID, logoURL: String? = nil, whatsappNumber: String?, instagramHandle: String?, tags: [String]) {
        guard let index = businesses.firstIndex(where: { $0.id == businessID }) else { return }
        let b = businesses[index]
        let cleanLogo = logoURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalLogo = (cleanLogo?.isEmpty ?? true) ? b.logoURL : cleanLogo

        businesses[index] = Business(
            id: b.id, townID: b.townID, name: b.name, category: b.category,
            summary: b.summary, etaMinutes: b.etaMinutes, deliveryPrice: b.deliveryPrice,
            rating: b.rating, reviewCount: b.reviewCount, isOpen: b.isOpen,
            symbol: b.symbol, colorName: b.colorName, products: b.products,
            tags: tags, whatsappNumber: whatsappNumber, instagramHandle: instagramHandle, ownerID: b.ownerID, logoURL: finalLogo
        )
    }

    func publishSpot(name: String, description: String, category: SpotCategory, locationNote: String, photoURL: String?, author: String) {
        guard let townID = selectedTown?.id else { return }
        let cleanURL = photoURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalPhotoURL = (cleanURL?.isEmpty ?? true) ? nil : cleanURL
        let initialPhotos = finalPhotoURL != nil ? [finalPhotoURL!] : []

        let newSpot = TownSpot(
            id: UUID(),
            townID: townID,
            author: author,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            locationNote: locationNote.trimmingCharacters(in: .whitespacesAndNewlines),
            photoSymbol: category.symbol,
            photoURL: finalPhotoURL,
            photos: initialPhotos,
            reviews: [],
            likesCount: 1,
            isLiked: true
        )
        spots.insert(newSpot, at: 0)

        let activityItem = ActivityItem(
            id: UUID(),
            title: "Spot Publicado en Pueblo",
            subtitle: newSpot.name,
            date: Date(),
            symbol: "camera.fill",
            status: .completed
        )
        activity.insert(activityItem, at: 0)
    }

    func addReviewToSpot(spotID: UUID, comment: String, rating: Int, photoURL: String?, author: String) {
        guard let index = spots.firstIndex(where: { $0.id == spotID }) else { return }
        let cleanURL = photoURL?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalURL = (cleanURL?.isEmpty ?? true) ? nil : cleanURL
        let newReview = SpotReview(
            id: UUID(),
            author: author,
            comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
            rating: rating,
            photoURL: finalURL,
            createdAt: Date()
        )
        spots[index].reviews.insert(newReview, at: 0)
        if let photo = finalURL, !spots[index].photos.contains(photo) {
            spots[index].photos.append(photo)
        }
    }

    func addPhotoToSpot(spotID: UUID, photoURL: String) {
        guard let index = spots.firstIndex(where: { $0.id == spotID }) else { return }
        let cleanURL = photoURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanURL.isEmpty, !spots[index].photos.contains(cleanURL) else { return }
        spots[index].photos.append(cleanURL)
        if spots[index].photoURL == nil {
            spots[index].photoURL = cleanURL
        }
    }

    func toggleSpotLike(id: UUID) {
        guard let index = spots.firstIndex(where: { $0.id == id }) else { return }
        spots[index].isLiked.toggle()
        spots[index].likesCount += spots[index].isLiked ? 1 : -1
    }
}
