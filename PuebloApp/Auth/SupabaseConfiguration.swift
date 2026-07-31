import Foundation

struct SupabaseConfiguration: Sendable {
    let projectURL: URL?
    let publishableKey: String
    let googleClientID: String
    let googleServerClientID: String

    static let main = SupabaseConfiguration(bundle: .main)

    init(bundle: Bundle) {
        let urlString = bundle.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        projectURL = URL(string: urlString)
        publishableKey = bundle.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String ?? ""
        googleClientID = bundle.object(forInfoDictionaryKey: "GIDClientID") as? String ?? ""
        googleServerClientID = bundle.object(forInfoDictionaryKey: "GIDServerClientID") as? String ?? ""
    }

    init(projectURL: URL?, publishableKey: String, googleClientID: String = "", googleServerClientID: String = "") {
        self.projectURL = projectURL
        self.publishableKey = publishableKey
        self.googleClientID = googleClientID
        self.googleServerClientID = googleServerClientID
    }

    var isSupabaseConfigured: Bool {
        projectURL != nil &&
        !projectURL!.absoluteString.contains("YOUR_PROJECT") &&
        !publishableKey.isEmpty &&
        !publishableKey.contains("YOUR_PUBLISHABLE_KEY")
    }

    var isGoogleConfigured: Bool {
        !googleClientID.isEmpty &&
        !googleClientID.contains("YOUR_IOS_CLIENT_ID") &&
        !googleServerClientID.isEmpty &&
        !googleServerClientID.contains("YOUR_WEB_CLIENT_ID")
    }
}
