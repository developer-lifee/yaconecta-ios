import SwiftUI

struct TownPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(MarketplaceStore.self) private var store

    var body: some View {
        NavigationStack {
            List(store.towns) { town in
                Button {
                    store.selectTown(town)
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "building.2.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.coral)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(town.name)
                                .font(.headline)
                                .foregroundStyle(AppTheme.ink)
                            Text("\(town.region) · \(town.activeBusinesses) comercios")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if store.selectedTown?.id == town.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppTheme.moss)
                        }
                    }
                }
                .accessibilityIdentifier("town-\(town.name)")
            }
            .navigationTitle("Elige un pueblo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
