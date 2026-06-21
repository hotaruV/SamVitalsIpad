import Foundation

struct NavigationItem: Decodable, Equatable, Identifiable, Sendable {
    let label: String
    let icon: String
    let route: String?
    let current: String?
    let subitems: [NavigationItem]

    var id: String {
        if let current = current?.nilIfBlank {
            return "current:\(current)"
        }

        if let route = route?.nilIfBlank {
            return "route:\(route)"
        }

        let childIdentity = subitems
            .map(\.id)
            .joined(separator: ",")

        return "group:\(label)|\(icon)|\(childIdentity)"
    }

    var isNavigable: Bool {
        route?.nilIfBlank != nil
    }

    var isExpandable: Bool {
        !isNavigable && !subitems.isEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case label
        case icon
        case route
        case current
        case subitems
    }

    init(
        label: String,
        icon: String,
        route: String? = nil,
        current: String? = nil,
        subitems: [NavigationItem] = []
    ) {
        self.label = label
        self.icon = icon
        self.route = route
        self.current = current
        self.subitems = subitems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        icon = try container.decode(String.self, forKey: .icon)
        route = try container.decodeIfPresent(String.self, forKey: .route)
        current = try container.decodeIfPresent(String.self, forKey: .current)
        subitems = try container.decodeIfPresent(
            [NavigationItem].self,
            forKey: .subitems
        ) ?? []
    }
}

private extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
