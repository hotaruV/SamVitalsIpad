import Foundation
import Security

struct TenantSession: Codable, Equatable {
    let token: String
    let tenantSlug: String
    let tenantURL: URL
    let resolvedAt: Date

    var loginURL: URL? {
        TenantResolution(
            token: token,
            tenantSlug: tenantSlug,
            tenantURL: tenantURL
        ).loginURL
    }
}

struct SessionStore {
    private let service = "com.codeforesolutions.samvitals.tenant-session"
    private let account = "active-tenant"

    func save(_ resolution: TenantResolution) throws {
        let session = TenantSession(
            token: resolution.token,
            tenantSlug: resolution.tenantSlug,
            tenantURL: resolution.tenantURL,
            resolvedAt: Date()
        )
        let data = try JSONEncoder().encode(session)
        let status = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )

        if status == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw SessionStoreError.keychain(addStatus)
            }
        } else if status != errSecSuccess {
            throw SessionStoreError.keychain(status)
        }
    }

    func load() throws -> TenantSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = result as? Data else {
            throw SessionStoreError.keychain(status)
        }

        do {
            return try JSONDecoder().decode(TenantSession.self, from: data)
        } catch {
            throw SessionStoreError.invalidData
        }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SessionStoreError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

enum SessionStoreError: LocalizedError {
    case keychain(OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .keychain:
            "No se pudo guardar la sesión de SamVitals de forma segura."
        case .invalidData:
            "La sesión guardada de SamVitals no es válida."
        }
    }
}
