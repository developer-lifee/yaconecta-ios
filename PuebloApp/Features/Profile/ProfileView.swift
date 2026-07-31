import SwiftUI

struct ProfileView: View {
    @Environment(MarketplaceStore.self) private var store
    @Environment(AuthStore.self) private var auth
    @Environment(AppRouter.self) private var router
    @State private var sellerRole = true
    @State private var courierRole = false

    var body: some View {
        List {
            Section {
                if let user = auth.currentUser {
                    HStack(spacing: 14) {
                        Text(initials(for: user.displayName))
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(AppTheme.coral, in: Circle())
                        VStack(alignment: .leading, spacing: 3) {
                            Text(user.displayName).font(.headline)
                            Text(user.email ?? "Cuenta Apple")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("Vecino de \(store.selectedTown?.name ?? "tu pueblo")")
                                .font(.caption).foregroundStyle(AppTheme.moss)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Participa con una cuenta", systemImage: "person.crop.circle.badge.plus")
                            .font(.headline)
                        Text("Inicia sesión para publicar noticias, solicitar servicios y construir reputación.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button("Continuar con Apple o Google") {
                            router.sheet = .signIn
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }
            }

            if auth.isSignedIn {
                Section("Mis roles") {
                    Toggle(isOn: $sellerRole) {
                        Label("Vendo productos o servicios", systemImage: "storefront.fill")
                    }
                    Toggle(isOn: $courierRole) {
                        Label("Hago domicilios o expresos", systemImage: "motorcycle.fill")
                    }
                }

                Section("Confianza") {
                    Label("Cuenta social verificada", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.moss)
                    LabeledContent("Tratos completados", value: "0")
                    LabeledContent("Confirmaciones útiles", value: "0")
                }
            }

            Section("Aplicación") {
                Label("Notificaciones", systemImage: "bell.fill")
                Label("Privacidad y seguridad", systemImage: "lock.shield.fill")
                Label("Ayuda a tu comunidad", systemImage: "person.3.fill")
                HStack {
                    Label("Modo sin conexión", systemImage: "arrow.triangle.2.circlepath")
                    Spacer()
                    Text("Preparado").foregroundStyle(AppTheme.moss)
                }
            }

            if auth.isSignedIn {
                Section {
                    Button("Cerrar sesión", role: .destructive) {
                        Task { await auth.signOut() }
                    }
                }
            }
        }
        .navigationTitle("Perfil")
    }

    private func initials(for name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }
}
