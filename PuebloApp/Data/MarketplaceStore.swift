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
                business.summary.localizedCaseInsensitiveContains(searchText)
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
            .filter { $0.townID == townID }
            .sorted {
                if $0.urgency == .urgent, $1.urgency != .urgent { return true }
                if $0.urgency != .urgent, $1.urgency == .urgent { return false }
                return $0.createdAt > $1.createdAt
            }
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
}
