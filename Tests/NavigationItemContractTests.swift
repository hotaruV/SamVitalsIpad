import Foundation

@main
enum NavigationItemContractTests {
    static func main() throws {
        try decodesNavigableItem()
        try decodesNestedExpandableGroup()
        try generatesStableIdentity()
        mapsHeroiconsToSFSymbols()
        resolvesOnlyTrustedTenantRoutes()
        print("NavigationItem contract tests passed")
    }

    private static func decodesNavigableItem() throws {
        let item = try decodeItem(from: """
        {
          "label": "Inicio",
          "icon": "home",
          "route": "/dashboard",
          "current": "tenant.dashboard"
        }
        """)

        assert(item.label == "Inicio")
        assert(item.icon == "home")
        assert(item.route == "/dashboard")
        assert(item.current == "tenant.dashboard")
        assert(item.subitems.isEmpty)
        assert(item.isNavigable)
        assert(!item.isExpandable)
    }

    private static func decodesNestedExpandableGroup() throws {
        let item = try decodeItem(from: """
        {
          "label": "Configuración",
          "icon": "cog-6-tooth",
          "route": null,
          "current": null,
          "subitems": [
            {
              "label": "Servicios",
              "icon": "adjustments-horizontal",
              "route": "/administracion/servicios",
              "current": "tenant.administracion.servicios",
              "subitems": [
                {
                  "label": "Usuarios",
                  "icon": "users",
                  "route": "/administracion/servicios/usuarios/operativos",
                  "current": "tenant.create.users"
                }
              ]
            }
          ]
        }
        """)

        assert(!item.isNavigable)
        assert(item.isExpandable)
        assert(item.subitems.count == 1)
        assert(item.subitems[0].subitems.count == 1)
        assert(item.subitems[0].subitems[0].isNavigable)
    }

    private static func generatesStableIdentity() throws {
        let json = """
        {
          "label": "Inicio",
          "icon": "home",
          "route": "/dashboard",
          "current": "tenant.dashboard"
        }
        """

        let first = try decodeItem(from: json)
        let second = try decodeItem(from: json)

        assert(first.id == "current:tenant.dashboard")
        assert(first.id == second.id)
    }

    private static func mapsHeroiconsToSFSymbols() {
        let expected = [
            "home": "house",
            "calendar-days": "calendar",
            "user-group": "person.3",
            "credit-card": "creditcard",
            "clipboard-document-list": "doc.text",
            "video-camera": "video",
            "cog-6-tooth": "gearshape"
        ]

        expected.forEach { heroicon, systemName in
            assert(NavigationIconMapper.systemName(for: heroicon) == systemName)
        }

        assert(
            NavigationIconMapper.systemName(for: "unknown-icon") ==
                NavigationIconMapper.fallbackSystemName
        )
    }

    private static func resolvesOnlyTrustedTenantRoutes() {
        let resolver = TenantRouteResolver()
        let tenantURL = URL(string: "https://demo.samvitals.com/login")!

        assert(
            resolver.destinationURL(
                for: "/dashboard",
                relativeTo: tenantURL
            )?.absoluteString == "https://demo.samvitals.com/dashboard"
        )
        assert(
            resolver.destinationURL(
                for: "menu/agenda?day=today",
                relativeTo: tenantURL
            )?.absoluteString == "https://demo.samvitals.com/menu/agenda?day=today"
        )
        assert(
            resolver.destinationURL(
                for: "https://evil.example/dashboard",
                relativeTo: tenantURL
            ) == nil
        )
        assert(
            resolver.destinationURL(
                for: "http://demo.samvitals.com/dashboard",
                relativeTo: tenantURL
            ) == nil
        )
        assert(
            resolver.destinationURL(
                for: "https://demo.samvitals.com:8443/dashboard",
                relativeTo: tenantURL
            ) == nil
        )
    }

    private static func decodeItem(from json: String) throws -> NavigationItem {
        try JSONDecoder().decode(
            NavigationItem.self,
            from: Data(json.utf8)
        )
    }
}
