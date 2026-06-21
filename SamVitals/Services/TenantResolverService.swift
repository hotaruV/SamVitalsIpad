import Foundation
import UIKit

struct TenantResolverService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func resolve(samVitalsID: String) async throws -> TenantResolution {
        let normalizedSamVitalsID = samVitalsID
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !normalizedSamVitalsID.isEmpty else {
            throw TenantResolverError.invalidSamVitalsID(nil)
        }

        let device = await MainActor.run { DeviceMetadata.current }
        let endpoint = AppEnvironment.apiBaseURL
            .appendingPathComponent("api/mobile/tenant/resolve")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            ResolveRequest(
                samVitalsID: normalizedSamVitalsID,
                deviceID: device.id,
                deviceName: device.name,
                platform: "ios",
                appVersion: Bundle.main.object(
                    forInfoDictionaryKey: "CFBundleShortVersionString"
                ) as? String
            )
        )

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TenantResolverError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw error(for: httpResponse.statusCode, data: data)
            }

            do {
                return try JSONDecoder().decode(TenantResolution.self, from: data)
            } catch {
                throw TenantResolverError.invalidResponse
            }
        } catch let error as TenantResolverError {
            throw error
        } catch let error as URLError {
            throw TenantResolverError.network(error)
        } catch {
            throw TenantResolverError.unexpected
        }
    }

    private func error(for statusCode: Int, data: Data) -> TenantResolverError {
        let apiMessage = try? JSONDecoder()
            .decode(APIErrorResponse.self, from: data)
            .message

        switch statusCode {
        case 404:
            return .notFound(apiMessage)
        case 422:
            return .invalidSamVitalsID(apiMessage)
        case 429:
            return .rateLimited
        case 500...599:
            return .server(apiMessage)
        default:
            return .unexpected
        }
    }
}

enum TenantResolverError: LocalizedError {
    case invalidSamVitalsID(String?)
    case notFound(String?)
    case rateLimited
    case server(String?)
    case network(URLError)
    case invalidResponse
    case unexpected

    var errorDescription: String? {
        switch self {
        case .invalidSamVitalsID(let message):
            return message ?? "Ingresa un SamVitals ID válido."
        case .notFound(let message):
            return message ?? "SamVitals ID no encontrado."
        case .rateLimited:
            return "Realizaste demasiados intentos. Espera un momento e inténtalo nuevamente."
        case .server(let message):
            return message ?? "No pudimos validar tu SamVitals ID en este momento."
        case .network:
            return "No pudimos conectar con SamVitals. Revisa tu conexión a internet."
        case .invalidResponse:
            return "SamVitals respondió con información no válida. Intenta nuevamente."
        case .unexpected:
            return "Ocurrió un problema al validar tu SamVitals ID."
        }
    }
}
private enum AppEnvironment {
    static let apiBaseURL = URL(string: "https://samvitals.com")!
}

private struct ResolveRequest: Encodable {
    let samVitalsID: String
    let deviceID: String
    let deviceName: String
    let platform: String
    let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case samVitalsID = "samvitals_id"
        case deviceID = "device_id"
        case deviceName = "device_name"
        case platform
        case appVersion = "app_version"
    }
}

private struct APIErrorResponse: Decodable {
    let message: String
}

private struct DeviceMetadata: Sendable {
    let id: String
    let name: String

    @MainActor
    static var current: DeviceMetadata {
        let defaults = UserDefaults.standard
        let fallbackKey = "samVitalsFallbackDeviceID"
        let fallbackID: String

        if let savedID = defaults.string(forKey: fallbackKey) {
            fallbackID = savedID
        } else {
            fallbackID = UUID().uuidString
            defaults.set(fallbackID, forKey: fallbackKey)
        }

        return DeviceMetadata(
            id: UIDevice.current.identifierForVendor?.uuidString ?? fallbackID,
            name: UIDevice.current.name
        )
    }
}
