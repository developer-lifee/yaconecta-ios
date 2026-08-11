import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

struct SignInSheet: View {
    enum AuthMethod: String, CaseIterable, Identifiable {
        case social = "Social"
        case email = "Correo"
        var id: String { rawValue }
    }

    enum EmailMode {
        case signIn
        case signUp
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(AuthStore.self) private var auth

    @State private var selectedMethod: AuthMethod = .social
    @State private var emailMode: EmailMode = .signIn
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 56))
                        .foregroundStyle(AppTheme.coral)
                        .padding(.top, 12)

                    VStack(spacing: 6) {
                        Text("Únete a tu comunidad")
                            .font(.title2.bold())
                        Text("Tu cuenta ayuda a reducir el spam y da confianza a noticias, pedidos y acuerdos.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                    }

                    Picker("Método", selection: $selectedMethod) {
                        Text("Redes Sociales").tag(AuthMethod.social)
                        Text("Correo Electrónico").tag(AuthMethod.email)
                    }
                    .pickerStyle(.segmented)
                    .padding(.vertical, 4)

                    if selectedMethod == .social {
                        socialAuthView
                    } else {
                        emailAuthView
                    }

                    if auth.isWorking {
                        ProgressView("Conectando…")
                            .padding(.top, 8)
                    }

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer(minLength: 20)

                    Text("Al continuar aceptas las normas comunitarias y el tratamiento de datos de YaConecta.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .navigationTitle(emailMode == .signUp && selectedMethod == .email ? "Crear cuenta" : "Iniciar sesión")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var socialAuthView: some View {
        VStack(spacing: 14) {
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
        }
    }

    @ViewBuilder
    private var emailAuthView: some View {
        VStack(spacing: 16) {
            Picker("Modo", selection: $emailMode) {
                Text("Iniciar Sesión").tag(EmailMode.signIn)
                Text("Registrarse").tag(EmailMode.signUp)
            }
            .pickerStyle(.segmented)

            VStack(spacing: 12) {
                if emailMode == .signUp {
                    TextField("Nombre completo o apodo", text: $displayName)
                        .textContentType(.name)
                        .padding(14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                TextField("Correo electrónico", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                SecureField("Contraseña", text: $password)
                    .textContentType(emailMode == .signUp ? .newPassword : .password)
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }

            Button {
                Task {
                    if emailMode == .signUp {
                        await auth.signUpWithEmail(email: email, password: password, displayName: displayName)
                    } else {
                        await auth.signInWithEmail(email: email, password: password)
                    }
                    if auth.isSignedIn { dismiss() }
                }
            } label: {
                Text(emailMode == .signUp ? "Crear cuenta con correo" : "Entrar con correo")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(AppTheme.coral, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(email.isEmpty || password.isEmpty || (emailMode == .signUp && displayName.isEmpty))
            .opacity(email.isEmpty || password.isEmpty || (emailMode == .signUp && displayName.isEmpty) ? 0.6 : 1.0)
        }
    }
}
