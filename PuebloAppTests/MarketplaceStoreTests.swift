import XCTest
@testable import PuebloApp

@MainActor
final class MarketplaceStoreTests: XCTestCase {
    func testLoadSelectsFirstTownAndFiltersBusinesses() async {
        let store = MarketplaceStore(repository: DemoMarketplaceRepository())

        await store.load()

        XCTAssertEqual(store.selectedTown?.name, "Guaduas")
        XCTAssertEqual(store.filteredBusinesses.count, 4)
        store.selectedCategory = .pharmacy
        XCTAssertEqual(store.filteredBusinesses.map(\.name), ["Droguería La 13"])
    }

    func testPublishingRequestAddsRequestAndActivity() async {
        let store = MarketplaceStore(repository: DemoMarketplaceRepository())
        await store.load()
        let initialRequestCount = store.requests.count
        let initialActivityCount = store.activity.count
        var draft = RequestDraft()
        draft.title = "Necesito un domicilio"
        draft.detail = "Recoger un paquete en la plaza"

        store.publish(draft)

        XCTAssertEqual(store.requests.count, initialRequestCount + 1)
        XCTAssertEqual(store.activity.count, initialActivityCount + 1)
        XCTAssertEqual(store.requests.first?.author, "Tú")
    }

    func testInvalidDraftIsNotPublished() async {
        let store = MarketplaceStore(repository: DemoMarketplaceRepository())
        await store.load()
        let initialCount = store.requests.count

        store.publish(RequestDraft())

        XCTAssertEqual(store.requests.count, initialCount)
    }

    func testNewsIsFilteredBySelectedTown() async {
        let store = MarketplaceStore(repository: DemoMarketplaceRepository())
        await store.load()

        XCTAssertEqual(store.townNews.count, 3)
        store.selectTown(DemoData.honda)
        XCTAssertEqual(store.townNews.count, 1)
        XCTAssertEqual(store.townNews.first?.location, "Acceso al puente Navarro")
    }

    func testPublishingNewsStartsUnverified() async {
        let store = MarketplaceStore(repository: DemoMarketplaceRepository())
        await store.load()
        var draft = NewsDraft()
        draft.title = "Hay cierre temporal en la vía"
        draft.body = "La Policía está desviando los vehículos desde las tres de la tarde."
        draft.location = "Salida norte"
        draft.acceptsResponsibility = true

        store.publishNews(draft, author: "Ana")

        XCTAssertEqual(store.news.first?.author, "Ana")
        XCTAssertEqual(store.news.first?.verification, .unverified)
    }

    func testConfirmingNewsOnlyCountsOnce() async {
        let store = MarketplaceStore(repository: DemoMarketplaceRepository())
        await store.load()
        let news = try! XCTUnwrap(store.townNews.first)
        let initialCount = news.confirmationCount

        store.confirmNews(id: news.id)
        store.confirmNews(id: news.id)

        XCTAssertEqual(store.news.first(where: { $0.id == news.id })?.confirmationCount, initialCount + 1)
    }
}
