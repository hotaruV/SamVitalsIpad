import Combine
import Foundation

@MainActor
final class StartViewModel: ObservableObject {
    @Published var samVitalsID: String {
        didSet {
            if samVitalsID != oldValue {
                errorMessage = nil
            }
            saveIfNeeded()
        }
    }

    @Published var rememberSamVitalsID: Bool {
        didSet {
            if rememberSamVitalsID && !canRememberSamVitalsID {
                rememberSamVitalsID = false
                return
            }

            defaults.set(rememberSamVitalsID, forKey: Keys.rememberSamVitalsID)

            if rememberSamVitalsID {
                saveIfNeeded()
            } else {
                defaults.removeObject(forKey: Keys.lastSamVitalsID)
            }
        }
    }

    @Published private(set) var isResolving = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var loginURL: URL?
    @Published private(set) var token: String?
    @Published private(set) var canRememberSamVitalsID: Bool
    @Published private(set) var isRestoringSession = false
    @Published private(set) var sessionUnlockError: String?

    private let defaults: UserDefaults
    private let resolver: TenantResolverService
    private let biometricAuth: BiometricAuthService
    private let sessionStore: SessionStore
    private var pendingSession: TenantSession?

    init(
        defaults: UserDefaults = .standard,
        resolver: TenantResolverService? = nil,
        biometricAuth: BiometricAuthService? = nil,
        sessionStore: SessionStore? = nil
    ) {
        let resolver = resolver ?? TenantResolverService()
        let biometricAuth = biometricAuth ?? BiometricAuthService()
        let sessionStore = sessionStore ?? SessionStore()
        let storedSession = try? sessionStore.load()
        self.defaults = defaults
        self.resolver = resolver
        self.biometricAuth = biometricAuth
        self.sessionStore = sessionStore
        let canRemember = biometricAuth.canProtectRememberedID
        canRememberSamVitalsID = canRemember

        let shouldRemember = canRemember &&
            defaults.bool(forKey: Keys.rememberSamVitalsID)
        rememberSamVitalsID = shouldRemember
        samVitalsID = shouldRemember
            ? defaults.string(forKey: Keys.lastSamVitalsID) ?? ""
            : ""

        if let storedSession, storedSession.loginURL != nil {
            pendingSession = storedSession
            isRestoringSession = true
        }
    }

    func resolve() async {
        guard !isResolving else { return }

        samVitalsID = samVitalsID.normalizedSamVitalsID

        guard !samVitalsID.isEmpty else {
            errorMessage = "Ingresa tu SamVitals ID."
            return
        }

        isResolving = true
        errorMessage = nil
        defer { isResolving = false }

        do {
            let resolution = try await resolver.resolve(samVitalsID: samVitalsID)
            guard let destination = resolution.loginURL else {
                throw TenantResolverError.invalidResponse
            }

            try sessionStore.save(resolution)
            token = resolution.token
            loginURL = destination
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restoreSessionIfNeeded() async {
        guard let pendingSession,
              let destination = pendingSession.loginURL else {
            isRestoringSession = false
            return
        }

        sessionUnlockError = nil

        do {
            try await biometricAuth.authenticateForPrivacyLock()
            token = pendingSession.token
            loginURL = destination
            self.pendingSession = nil
            isRestoringSession = false
        } catch {
            sessionUnlockError = error.localizedDescription
        }
    }

    func forgetStoredSession() {
        try? sessionStore.clear()
        pendingSession = nil
        token = nil
        loginURL = nil
        sessionUnlockError = nil
        isRestoringSession = false
    }

    func toggleRememberSamVitalsID() {
        if rememberSamVitalsID {
            rememberSamVitalsID = false
            return
        }

        guard canRememberSamVitalsID else {
            errorMessage = "No puedes recordar tu SamVitals ID sin Face ID, Touch ID o un código configurado en tu dispositivo."
            return
        }

        errorMessage = nil
        rememberSamVitalsID = true
    }

    private func saveIfNeeded() {
        guard rememberSamVitalsID else { return }
        defaults.set(samVitalsID, forKey: Keys.lastSamVitalsID)
    }

    private enum Keys {
        // Evita restaurar el valor "demo" usado durante el desarrollo.
        static let lastSamVitalsID = "lastSamVitalsID.v2"
        static let rememberSamVitalsID = "rememberSamVitalsID.v2"
    }
}
