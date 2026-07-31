import SwiftUI

struct TownButton: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        Button {
            router.sheet = .chooseTown
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                Text(store.selectedTown?.name ?? "Elegir pueblo")
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption.bold())
            }
            .foregroundStyle(AppTheme.ink)
        }
        .accessibilityIdentifier("town-picker-button")
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatusPill: View {
    let status: RequestStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch status {
        case .published: AppTheme.coral
        case .agreed, .onTheWay: .blue
        case .completed: AppTheme.moss
        }
    }
}

struct RequestRow: View {
    let request: LocalRequest

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: request.category.symbol)
                    .font(.title3)
                    .foregroundStyle(AppTheme.coral)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.coral.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.title)
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                    Text("\(request.author) · \(request.createdAt, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if request.isMine { StatusPill(status: request.status) }
            }

            Text(request.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(request.area, systemImage: "mappin")
                Spacer()
                if let budget = request.budget {
                    Text("Hasta \(budget.colombianCurrency)")
                        .fontWeight(.semibold)
                } else {
                    Text("Precio a acordar")
                }
            }
            .font(.caption)
            .foregroundStyle(AppTheme.moss)

            if request.offerCount > 0 {
                Label("\(request.offerCount) \(request.offerCount == 1 ? "propuesta" : "propuestas")", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.caption.bold())
                    .foregroundStyle(AppTheme.coral)
            }
        }
        .padding(16)
        .cardSurface()
    }
}
