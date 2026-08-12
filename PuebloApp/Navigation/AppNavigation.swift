import Observation
import SwiftUI

enum AppTab: Hashable {
    case explore
    case news
    case requests
    case activity
    case profile
}

enum AppRoute: Hashable {
    case business(Business)
    case request(LocalRequest)
    case news(CommunityNews)
    case myBusiness
    case townSpots
    case activityHistory
}

enum SheetDestination: Identifiable, Hashable {
    case chooseTown
    case createRequest
    case createNews
    case signIn

    var id: String {
        switch self {
        case .chooseTown: "choose-town"
        case .createRequest: "create-request"
        case .createNews: "create-news"
        case .signIn: "sign-in"
        }
    }
}

@MainActor
@Observable
final class AppRouter {
    var path: [AppRoute] = []
    var sheet: SheetDestination?

    func navigate(to route: AppRoute) {
        path.append(route)
    }
}
