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

                            HStack(spacing: 4) {
                                if store.isAccountVerified {
                                    Label("Cuenta Verificada", systemImage: "checkmark.seal.fill")
                                        .font(.caption.bold())
                                        .foregroundStyle(.green)
                                } else {
                                    Label("Vecino en Progreso (\(store.missionsCompletedCount)/3)", systemImage: "clock.badge.checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.orange)
                                }
                            }

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
                Section("Nivel de Verificación y Misiones de Pueblo") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Progreso para verificar cuenta:")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(store.missionsCompletedCount)/3 Misiones")
                                .font(.caption.bold())
                                .foregroundStyle(store.isAccountVerified ? .green : .orange)
                        }

                        ProgressView(value: Double(store.missionsCompletedCount), total: 3.0)
                            .tint(store.isAccountVerified ? .green : AppTheme.coral)

                        Text(store.isAccountVerified ? "¡Felicidades! Has completado las misiones comunitarias y tu cuenta es Verificada." : "Completa misiones interactuando en la app para verificar tu cuenta de vecino:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    // Misión 1: Spots
                    HStack {
                        Image(systemName: store.userSpotsCount > 0 ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(store.userSpotsCount > 0 ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("📍 Publicar o recomendar 1 Spot del pueblo").font(.subheadline.weight(.semibold))
                            Text(store.userSpotsCount > 0 ? "¡Completado!" : "Publica un mirador o parche chill").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    // Misión 2: Noticias
                    HStack {
                        Image(systemName: store.usefulConfirmationsCount > 0 ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(store.usefulConfirmationsCount > 0 ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("💬 Confirmar 1 noticia útil comunitaria").font(.subheadline.weight(.semibold))
                            Text(store.usefulConfirmationsCount > 0 ? "¡Completado!" : "Apoya noticias de vecinos").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    // Misión 3: Comercio / Encargos
                    HStack {
                        Image(systemName: store.completedDealsCount > 0 ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(store.completedDealsCount > 0 ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("🤝 Completar 1 trato o pedido").font(.subheadline.weight(.semibold))
                            Text(store.completedDealsCount > 0 ? "¡Completado!" : "Compra o vende algo en tu pueblo").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Historial de Actividad y Reputación") {
                    LabeledContent("Tratos completados", value: "\(store.completedDealsCount)")
                    LabeledContent("Confirmaciones útiles", value: "\(store.usefulConfirmationsCount)")
                    LabeledContent("Spots publicados", value: "\(store.userSpotsCount)")

                    Button {
                        router.navigate(to: .activityHistory)
                    } label: {
                        HStack {
                            Label("Ver mi historial de actividad completo", systemImage: "clock.arrow.circlepath")
                                .font(.subheadline.bold())
                                .foregroundStyle(AppTheme.coral)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.bold())
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

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
