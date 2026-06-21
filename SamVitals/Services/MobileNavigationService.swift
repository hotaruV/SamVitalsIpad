import Foundation
import WebKit

struct MobileNavigationService {
    private let session: URLSession
    private let websiteDataStore: WKWebsiteDataStore

    init(
        session: URLSession? = nil,
        websiteDataStore: WKWebsiteDataStore = .default()
    ) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.httpCookieStorage = .shared
            configuration.httpShouldSetCookies = true
            configuration.timeoutIntervalForRequest = 20
            self.session = URLSession(configuration: configuration)
        }

        self.websiteDataStore = websiteDataStore
    }

    func loadItems(for tenantURL: URL) async throws -> [NavigationItem] {
        let endpoint = try navigationEndpoint(for: tenantURL)
        try await synchronizeCookies(for: endpoint)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("ios", forHTTPHeaderField: "X-SamVitals-App")
        request.setValue("ipad", forHTTPHeaderField: "X-SamVitals-Device")

        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw MobileNavigationError.invalidResponse
            }

            guard response.url?.host?.lowercased() == endpoint.host?.lowercased() else {
                throw MobileNavigationError.untrustedRedirect
            }

            switch response.statusCode {
            case 200...299:
                break
            case 401, 403:
                throw MobileNavigationError.authenticationRequired
            default:
                throw MobileNavigationError.server(response.statusCode)
            }

            let contentType = response.value(forHTTPHeaderField: "Content-Type") ?? ""
            guard contentType.localizedCaseInsensitiveContains("application/json") else {
                throw MobileNavigationError.authenticationRequired
            }

            do {
                let items = try JSONDecoder()
                    .decode(MobileNavigationResponse.self, from: data)
                    .items
                return removingBillingItems(from: items)
            } catch {
                throw MobileNavigationError.invalidResponse
            }
        } catch let error as MobileNavigationError {
            throw error
        } catch let error as URLError {
            throw MobileNavigationError.network(error)
        } catch {
            throw MobileNavigationError.unexpected
        }
    }

    private func removingBillingItems(
        from items: [NavigationItem]
    ) -> [NavigationItem] {
        items.compactMap { item in
            guard item.label != "Planes y Módulos" else { return nil }

            let subitems = removingBillingItems(from: item.subitems)
            guard item.isNavigable || !subitems.isEmpty else { return nil }

            return NavigationItem(
                label: item.label,
                icon: item.icon,
                route: item.route,
                current: item.current,
                subitems: subitems
            )
        }
    }

    private func navigationEndpoint(for tenantURL: URL) throws -> URL {
        guard var components = URLComponents(
            url: tenantURL,
            resolvingAgainstBaseURL: false
        ), components.scheme?.lowercased() == "https",
           components.host != nil else {
            throw MobileNavigationError.invalidTenantURL
        }

        components.path = "/mobile/navigation"
        components.query = nil
        components.fragment = nil

        guard let url = components.url else {
            throw MobileNavigationError.invalidTenantURL
        }

        return url
    }

    private func synchronizeCookies(for url: URL) async throws {
        let cookies = await withCheckedContinuation { continuation in
            websiteDataStore.httpCookieStore.getAllCookies { cookies in
                continuation.resume(returning: cookies)
            }
        }

        cookies
            .filter { cookie in
                let domain = cookie.domain.trimmingCharacters(in: CharacterSet(charactersIn: "."))
                return url.host == domain || url.host?.hasSuffix(".\(domain)") == true
            }
            .forEach(HTTPCookieStorage.shared.setCookie)
    }
}

enum MobileNavigationError: LocalizedError {
    case invalidTenantURL
    case untrustedRedirect
    case authenticationRequired
    case server(Int)
    case network(URLError)
    case invalidResponse
    case unexpected

    var errorDescription: String? {
        switch self {
        case .invalidTenantURL, .untrustedRedirect:
            "No se pudo verificar la dirección del tenant."
        case .authenticationRequired:
            "Inicia sesión en SamVitals y vuelve a abrir el menú."
        case .server:
            "No pudimos cargar el menú en este momento."
        case .network:
            "Revisa tu conexión a internet e inténtalo nuevamente."
        case .invalidResponse:
            "El menú recibido no tiene un formato válido."
        case .unexpected:
            "Ocurrió un problema al cargar el menú."
        }
    }
}

private struct MobileNavigationResponse: Decodable {
    let items: [NavigationItem]
}
