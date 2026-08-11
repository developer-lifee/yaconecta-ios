import SwiftUI

struct AppShellView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @State private var selectedTab: AppTab = .explore

    var body: some View {
        Group {
            switch store.loadState {
            case .idle, .loading:
                LaunchLoadingView()
            case .failed(let message):
                LoadErrorView(message: message)
            case .loaded:
                tabs
            }
        }
        .task { await store.load() }
        .task { await auth.restoreSession() }
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            AppTabStack(root: ExploreView())
                .tabItem { Label("Explorar", systemImage: "safari.fill") }
                .tag(AppTab.explore)

            AppTabStack(root: NewsView())
                .tabItem { Label("Noticias", systemImage: "newspaper.fill") }
                .tag(AppTab.news)

            AppTabStack(root: RequestsView())
                .tabItem { Label("Solicitudes", systemImage: "megaphone.fill") }
                .tag(AppTab.requests)

            AppTabStack(root: ActivityView())
                .tabItem { Label("Actividad", systemImage: "bolt.fill") }
                .tag(AppTab.activity)

            AppTabStack(root: ProfileView())
                .tabItem { Label("Perfil", systemImage: "person.crop.circle.fill") }
                .tag(AppTab.profile)
        }
    }
}

private struct AppTabStack<Root: View>: View {
    @State private var router = AppRouter()
    let root: Root

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            root
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .business(let business):
                        BusinessDetailView(business: business)
                    case .request(let request):
                        RequestDetailView(request: request)
                    case .news(let news):
                        NewsDetailView(newsID: news.id)
                    case .myBusiness:
                        MyBusinessView()
                    case .townSpots:
                        TownSpotsView()
                    }
                }
        }
        .sheet(item: $router.sheet) { destination in
            switch destination {
            case .chooseTown:
                TownPickerSheet()
            case .createRequest:
                CreateRequestSheet()
            case .createNews:
                CreateNewsSheet()
            case .signIn:
                SignInSheet()
            }
        }
        .environment(router)
    }
}

private struct LaunchLoadingView: View {
    var body: some View {
        ZStack {
            AppTheme.sand.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.coral)
                Text("YaConecta")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ink)
                ProgressView()
                    .tint(AppTheme.coral)
            }
        }
        .accessibilityIdentifier("launch-loading")
    }
}

private struct LoadErrorView: View {
    @Environment(MarketplaceStore.self) private var store
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Sin conexión", systemImage: "wifi.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Intentar de nuevo") {
                Task { await store.retry() }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("App") {
    AppShellView()
        .environment(MarketplaceStore(repository: DemoMarketplaceRepository()))
        .environment(AuthStore.preview)
}
