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
                            Text(user.email ?? "Cuenta verificada")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("Vecino de \(store.selectedTown?.name ?? "tu pueblo")")
                                .font(.caption).foregroundStyle(AppTheme.moss)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(alignment: .center, spacing: 14) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(AppTheme.coral)

                        VStack(spacing: 4) {
                            Text("Sin sesión activa")
                                .font(.headline)
                            Text("Inicia sesión o crea tu cuenta con Correo, Apple o Google para publicar en la comunidad.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            router.sheet = .signIn
                        } label: {
                            Text("Iniciar sesión / Registrarse")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 12)
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

                if sellerRole {
                    Section("Gestión Comercial") {
                        Button {
                            router.navigate(to: .myBusiness)
                        } label: {
                            HStack {
                                Label("Gestionar Mi Negocio y Estantería", systemImage: "building.2.crop.circle.fill")
                                    .font(.body.bold())
                                    .foregroundStyle(AppTheme.coral)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }

                Section("Confianza y Reputación") {
                    Label("Cuenta verificada", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(AppTheme.moss)
                    LabeledContent("Tratos completados", value: "0")
                    LabeledContent("Confirmaciones útiles", value: "0")
                }
            } else {
                Section("Gestión Comercial") {
                    Button {
                        router.sheet = .signIn
                    } label: {
                        HStack {
                            Label("Iniciar sesión para gestionar Mi Negocio", systemImage: "storefront")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
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
