import Foundation

enum NavigationIconMapper {
    static let fallbackSystemName = "square.grid.2x2"

    static func systemName(for heroicon: String) -> String {
        symbols[normalized(heroicon)] ?? fallbackSystemName
    }

    private static let symbols: [String: String] = [
        "adjustments-horizontal": "slider.horizontal.3",
        "archive-box": "archivebox",
        "banknotes": "banknote",
        "beaker": "testtube.2",
        "calendar-days": "calendar",
        "clipboard-document-list": "doc.text",
        "cog-6-tooth": "gearshape",
        "credit-card": "creditcard",
        "document-text": "doc.text",
        "folder-open": "folder",
        "heart": "heart",
        "home": "house",
        "squares-2x2": "square.grid.2x2",
        "truck": "truck.box",
        "user-group": "person.3",
        "user-plus": "person.badge.plus",
        "users": "person.2",
        "video-camera": "video",
        "wrench-screwdriver": "wrench.and.screwdriver"
    ]

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
    }
}
