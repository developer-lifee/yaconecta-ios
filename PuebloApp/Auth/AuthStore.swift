import AuthenticationServices
import Foundation
import GoogleSignIn
import Observation
import Supabase
import UIKit

struct AuthenticatedUser: Equatable, Sendable {
    let id: UUID
    let displayName: String
    let email: String?
    var avatarURL: String? = nil
}

@MainActor
@Observable
final class AuthStore {
    enum State: Equatable {
        case checking
        case signedOut
        case signedIn(AuthenticatedUser)
        case unconfigured
    }

    private let configuration: SupabaseConfiguration
    let client: SupabaseClient?

    var state: State
    var isWorking = false
    var errorMessage: String?

    init(configuration: SupabaseConfiguration = .main) {
        self.configuration = configuration
        if configuration.isSupabaseConfigured, let url = configuration.projectURL {
            client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: configuration.publishableKey,
                options: .init(auth: .init(flowType: .pkce))
            )
            state = .checking
        } else {
            client = nil
            state = .unconfigured
        }
    }

    var currentUser: AuthenticatedUser? {
        if case .signedIn(let user) = state { return user }
        return nil
    }

    var isSignedIn: Bool { currentUser != nil }
    var isConfigured: Bool { client != nil }

    func restoreSession() async {
        guard case .checking = state, let client else { return }
        do {
            let session = try await client.auth.session
            state = .signedIn(Self.user(from: session.user))
        } catch {
            state = .signedOut
        }
    }

    func signInWithGoogle() async {
        guard let client else {
            errorMessage = "Agrega las credenciales de Supabase antes de iniciar sesión."
            return
        }
        guard configuration.isGoogleConfigured else {
            errorMessage = "Faltan los Client ID de Google en Info.plist."
            return
        }
        guard let presentingViewController = UIApplication.shared.topViewController else {
            errorMessage = "No pudimos abrir el inicio de sesión de Google."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(
                clientID: configuration.googleClientID,
                serverClientID: configuration.googleServerClientID
            )
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthPresentationError.missingGoogleToken
            }
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(
                    provider: .google,
                    idToken: idToken,
                    accessToken: result.user.accessToken.tokenString
                )
            )
            state = .signedIn(Self.user(from: session.user))
        } catch {
            if (error as NSError).code != GIDSignInError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        guard let client else {
            errorMessage = "Agrega las credenciales de Supabase antes de iniciar sesión."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            guard let credential = try result.get().credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8) else {
                throw AuthPresentationError.missingAppleToken
            }

            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken)
            )

            let nameParts = [
                credential.fullName?.givenName,
                credential.fullName?.middleName,
                credential.fullName?.familyName
            ].compactMap { $0 }.filter { !$0.isEmpty }

            if !nameParts.isEmpty {
                try await client.auth.update(
                    user: UserAttributes(data: [
                        "full_name": .string(nameParts.joined(separator: " ")),
                        "given_name": .string(credential.fullName?.givenName ?? ""),
                        "family_name": .string(credential.fullName?.familyName ?? "")
                    ])
                )
            }
            state = .signedIn(Self.user(from: session.user, fallbackName: nameParts.joined(separator: " ")))
        } catch {
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signInWithEmail(email: String, password: String) async {
        guard let client else {
            errorMessage = "Agrega las credenciales de Supabase antes de iniciar sesión."
            return
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor ingresa tu correo y contraseña."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let session = try await client.auth.signIn(email: trimmedEmail, password: password)
            state = .signedIn(Self.user(from: session.user))
        } catch {
            errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
        }
    }

    func signUpWithEmail(email: String, password: String, displayName: String) async {
        guard let client else {
            errorMessage = "Agrega las credenciales de Supabase antes de iniciar sesión."
            return
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Por favor completa el correo y la contraseña."
            return
        }
        guard password.count >= 6 else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres."
            return
        }

        isWorking = true
        errorMessage = nil
        defer { isWorking = false }

        do {
            let response = try await client.auth.signUp(
                email: trimmedEmail,
                password: password,
                data: [
                    "full_name": .string(trimmedName.isEmpty ? "Vecino" : trimmedName)
                ]
            )
            state = .signedIn(Self.user(from: response.user, fallbackName: trimmedName))
        } catch {
            errorMessage = "Error al registrarse: \(error.localizedDescription)"
        }
    }

    func signOut() async {
        guard let client else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await client.auth.signOut()
            GIDSignIn.sharedInstance.signOut()
            state = .signedOut
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func user(from user: User, fallbackName: String = "") -> AuthenticatedUser {
        let metadataName = user.userMetadata["full_name"]?.stringValue
        let emailName = user.email?.split(separator: "@").first.map(String.init) ?? "Vecino"
        return AuthenticatedUser(
            id: user.id,
            displayName: metadataName?.isEmpty == false ? metadataName! : (fallbackName.isEmpty ? emailName : fallbackName),
            email: user.email
        )
    }

    static let preview = AuthStore(configuration: .init(projectURL: nil, publishableKey: ""))
}

private enum AuthPresentationError: LocalizedError {
    case missingGoogleToken
    case missingAppleToken

    var errorDescription: String? {
        switch self {
        case .missingGoogleToken: "Google no entregó un token de identidad."
        case .missingAppleToken: "Apple no entregó un token de identidad."
        }
    }
}

private extension UIApplication {
    var topViewController: UIViewController? {
        let scenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let root = scenes.flatMap(\.windows).first(where: \.isKeyWindow)?.rootViewController
        return root?.presentedViewController ?? root
    }
}
