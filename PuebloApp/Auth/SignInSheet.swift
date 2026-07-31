import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

struct SignInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var auth

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.coral)
                VStack(spacing: 8) {
                    Text("Únete a tu comunidad")
                        .font(.title.bold())
                    Text("Tu cuenta ayuda a reducir el spam y da confianza a noticias, pedidos y acuerdos.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                if auth.isConfigured {
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        Task {
                            await auth.signInWithApple(result: result)
                            if auth.isSignedIn { dismiss() }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityIdentifier("sign-in-apple")

                    GoogleSignInButton {
                        Task {
                            await auth.signInWithGoogle()
                            if auth.isSignedIn { dismiss() }
                        }
                    }
                    .frame(height: 50)
                    .accessibilityIdentifier("sign-in-google")
                } else {
                    ContentUnavailableView {
                        Label("Supabase por configurar", systemImage: "wrench.and.screwdriver.fill")
                    } description: {
                        Text("Reemplaza las credenciales de ejemplo en Supporting/Info.plist para activar el registro.")
                    }
                }

                if auth.isWorking { ProgressView("Conectando…") }
                if let error = auth.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                Spacer()
                Text("Al continuar aceptas las normas comunitarias y el tratamiento de datos de YaConecta.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .navigationTitle("Iniciar sesión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}
