import SwiftUI

struct ActivityView: View {
    @Environment(MarketplaceStore.self) private var store

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(store.activity) { item in
                    HStack(spacing: 14) {
                        Image(systemName: item.symbol)
                            .font(.title3)
                            .foregroundStyle(AppTheme.coral)
                            .frame(width: 48, height: 48)
                            .background(AppTheme.coral.opacity(0.1), in: Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.headline)
                            Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
                            Text(item.date, style: .relative).font(.caption).foregroundStyle(.tertiary)
                        }
                        Spacer()
                        StatusPill(status: item.status)
                    }
                    .padding(16)
                    .cardSurface()
                }
            }
            .padding(18)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Actividad")
    }
}
