import LocalAuthentication

struct BiometricAuthService {
    var canProtectRememberedID: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func authenticateForPrivacyLock() async throws {
        let context = LAContext()
        context.localizedCancelTitle = "Cancelar"
        context.localizedFallbackTitle = "Usar código"
        var evaluationError: NSError?

        // Sin protección configurada no bloqueamos el acceso al tenant.
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthentication,
            error: &evaluationError
        ) else {
            return
        }

        do {
            let granted = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Desbloquea SamVitals para abrir tu consultorio"
            )

            guard granted else {
                throw BiometricAuthError.verificationFailed
            }
        } catch let error as BiometricAuthError {
            throw error
        } catch {
            throw BiometricAuthError.verificationFailed
        }
    }
}

enum BiometricAuthError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            "No se pudo verificar tu identidad para abrir SamVitals."
        }
    }
}
