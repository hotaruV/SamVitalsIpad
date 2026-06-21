import Foundation

struct TenantRouteResolver {
    func destinationURL(for route: String, relativeTo tenantURL: URL) -> URL? {
        let route = route.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !route.isEmpty,
              var origin = URLComponents(
                  url: tenantURL,
                  resolvingAgainstBaseURL: false
              ) else {
            return nil
        }

        origin.path = "/"
        origin.query = nil
        origin.fragment = nil

        guard let originURL = origin.url,
              let destination = URL(string: route, relativeTo: originURL)?.absoluteURL,
              let components = URLComponents(
                  url: destination,
                  resolvingAgainstBaseURL: false
              ),
              components.scheme?.lowercased() == origin.scheme?.lowercased(),
              components.host?.lowercased() == origin.host?.lowercased(),
              components.port == origin.port else {
            return nil
        }

        return destination
    }
}
