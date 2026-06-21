//
//  TenantResolution.swift
//  SamVitals
//
//  Created by CarlosV on 19/06/26.
//

import Foundation

struct TenantResolution: Decodable, Equatable {
    let token: String
    let tenantSlug: String
    let tenantURL: URL

    enum CodingKeys: String, CodingKey {
        case token
        case tenantSlug = "tenant_slug"
        case tenantURL = "tenant_url"
    }

    var loginURL: URL? {
        guard var components = URLComponents(
            url: tenantURL,
            resolvingAgainstBaseURL: false
        ) else {
            return nil
        }

        let expectedHost = "\(tenantSlug.lowercased()).samvitals.com"
        guard components.scheme?.lowercased() == "https",
              components.host?.lowercased() == expectedHost else {
            return nil
        }

        components.path = "/login"
        components.query = nil
        components.fragment = nil
        return components.url
    }
}

extension String {
    var samVitalsIDInput: String {
        let folded = folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "es_MX")
        )
        let slug = folded
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "-",
                options: .regularExpression
            )
        return String(slug.drop { $0 == "-" })
    }

    var normalizedSamVitalsID: String {
        samVitalsIDInput.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
