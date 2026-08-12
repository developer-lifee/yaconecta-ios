import Foundation
import Supabase

struct SupabaseNewsService {
    private let client: SupabaseClient?

    init(client: SupabaseClient?) {
        self.client = client
    }

    var isConfigured: Bool { client != nil }

    func fetchNews(townID: UUID) async throws -> [CommunityNews] {
        guard let client else { return [] }
        let rows: [NewsRow] = try await client
            .from("local_news")
            .select(
                "id,town_id,title,body,category,urgency,location_text,source_note,verification,confirmation_count,image_url,is_regional,created_at,profiles!local_news_author_id_fkey(display_name)"
            )
            .or("town_id.eq.\(townID.uuidString),is_regional.eq.true")
            .eq("moderation", value: "published")
            .order("created_at", ascending: false)
            .execute()
            .value
        return rows.map(\.communityNews)
    }

    func publish(_ draft: NewsDraft, townID: UUID, user: AuthenticatedUser) async throws -> CommunityNews {
        guard let client else { throw NewsBackendError.notConfigured }

        try await client
            .from("profiles")
            .update(ProfileTownUpdate(townID: townID))
            .eq("id", value: user.id.uuidString)
            .execute()

        let payload = NewNewsRow(
            townID: townID,
            authorID: user.id,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            body: draft.body.trimmingCharacters(in: .whitespacesAndNewlines),
            category: draft.category.databaseValue,
            urgency: draft.urgency.databaseValue,
            locationText: draft.location.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceNote: draft.sourceNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : draft.sourceNote.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: draft.imageURL,
            isRegional: draft.isRegional
        )

        let row: NewsRow = try await client
            .from("local_news")
            .insert(payload)
            .select(
                "id,town_id,title,body,category,urgency,location_text,source_note,verification,confirmation_count,image_url,is_regional,created_at,profiles!local_news_author_id_fkey(display_name)"
            )
            .single()
            .execute()
            .value
        return row.communityNews
    }

    func confirm(newsID: UUID, userID: UUID) async throws {
        guard let client else { throw NewsBackendError.notConfigured }
        try await client
            .from("news_confirmations")
            .upsert(NewsConfirmationRow(newsID: newsID, userID: userID))
            .execute()
    }
}

private struct ProfileTownUpdate: Encodable, Sendable {
    let townID: UUID

    enum CodingKeys: String, CodingKey {
        case townID = "town_id"
    }
}

private struct NewNewsRow: Encodable, Sendable {
    let townID: UUID
    let authorID: UUID
    let title: String
    let body: String
    let category: String
    let urgency: String
    let locationText: String
    let sourceNote: String?
    let imageURL: String?
    let isRegional: Bool

    enum CodingKeys: String, CodingKey {
        case townID = "town_id"
        case authorID = "author_id"
        case title, body, category, urgency
        case locationText = "location_text"
        case sourceNote = "source_note"
        case imageURL = "image_url"
        case isRegional = "is_regional"
    }
}

private struct NewsConfirmationRow: Encodable, Sendable {
    let newsID: UUID
    let userID: UUID

    enum CodingKeys: String, CodingKey {
        case newsID = "news_id"
        case userID = "user_id"
    }
}

private struct NewsAuthorRow: Decodable, Sendable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

private struct NewsRow: Decodable, Sendable {
    let id: UUID
    let townID: UUID
    let title: String
    let body: String
    let category: String
    let urgency: String
    let locationText: String
    let sourceNote: String?
    let verification: String
    let confirmationCount: Int
    let imageURL: String?
    let isRegional: Bool?
    let createdAt: Date
    let profiles: NewsAuthorRow?

    enum CodingKeys: String, CodingKey {
        case id
        case townID = "town_id"
        case title, body, category, urgency
        case locationText = "location_text"
        case sourceNote = "source_note"
        case verification
        case confirmationCount = "confirmation_count"
        case imageURL = "image_url"
        case isRegional = "is_regional"
        case createdAt = "created_at"
        case profiles
    }

    var communityNews: CommunityNews {
        CommunityNews(
            id: id,
            townID: townID,
            author: profiles?.displayName ?? "Vecino",
            title: title,
            body: body,
            category: NewsCategory(databaseValue: category),
            urgency: NewsUrgency(databaseValue: urgency),
            location: locationText,
            createdAt: createdAt,
            sourceNote: sourceNote,
            verification: VerificationStatus(databaseValue: verification),
            confirmationCount: confirmationCount,
            didConfirm: false,
            imageURL: imageURL,
            isRegional: isRegional ?? false
        )
    }
}

private enum NewsBackendError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "Supabase todavía no está configurado."
    }
}

private extension NewsCategory {
    var databaseValue: String {
        switch self {
        case .roads: "roads"
        case .emergency: "emergency"
        case .publicService: "public_service"
        case .community: "community"
        case .mourning: "mourning"
        }
    }

    init(databaseValue: String) {
        switch databaseValue {
        case "emergency": self = .emergency
        case "public_service": self = .publicService
        case "community": self = .community
        case "mourning": self = .mourning
        default: self = .roads
        }
    }
}

private extension NewsUrgency {
    var databaseValue: String {
        switch self {
        case .informative: "informative"
        case .important: "important"
        case .urgent: "urgent"
        }
    }

    init(databaseValue: String) {
        switch databaseValue {
        case "informative": self = .informative
        case "urgent": self = .urgent
        default: self = .important
        }
    }
}

private extension VerificationStatus {
    init(databaseValue: String) {
        switch databaseValue {
        case "verified": self = .verified
        case "community_confirmed": self = .communityConfirmed
        default: self = .unverified
        }
    }
}
