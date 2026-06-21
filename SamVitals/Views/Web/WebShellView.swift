import SwiftUI
import WebKit

struct WebShellView: View {
    let initialURL: URL

    @State private var currentURL: URL
    @State private var isDrawerOpen = false
    @State private var navigationItems: [NavigationItem]
    @State private var isAppCookieReady = false
    @State private var isLoadingNavigation = false
    @State private var navigationError: String?

    private let navigationService: MobileNavigationService
    private let routeResolver = TenantRouteResolver()

    init(
        initialURL: URL,
        navigationItems: [NavigationItem] = [],
        navigationService: MobileNavigationService? = nil
    ) {
        self.initialURL = initialURL
        self.navigationService = navigationService ?? MobileNavigationService()
        _currentURL = State(initialValue: initialURL)
        _navigationItems = State(initialValue: navigationItems)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                webContent

                if isDrawerOpen {
                    Color.black.opacity(0.28)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    DrawerMenuView(
                        items: navigationItems,
                        isLoading: isLoadingNavigation,
                        errorMessage: navigationError,
                        onSelect: handleSelection,
                        onRetry: reloadNavigationItems,
                        onClose: closeDrawer
                    )
                    .frame(width: drawerWidth(for: geometry.size.width))
                    .frame(maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .clipShape(
                        UnevenRoundedRectangle(
                            bottomTrailingRadius: 26,
                            topTrailingRadius: 26
                        )
                    )
                    .shadow(color: .black.opacity(0.22), radius: 28, x: 12, y: 0)
                    .transition(.move(edge: .leading))
                    .ignoresSafeArea(edges: .vertical)
                }
            }
            .overlay(alignment: .topLeading) {
                if !isDrawerOpen {
                    menuButton
                        .padding(.leading, 16)
                        .padding(.top, geometry.safeAreaInsets.top + 35)
                }
            }
        }
        .animation(.easeInOut(duration: 0.24), value: isDrawerOpen)
        .task(id: initialURL) {
            await prepareAppCookie()
            await loadNavigationItems(force: false)
        }
    }

    @ViewBuilder
    private var webContent: some View {
        if isAppCookieReady {
            SamVitalsWebView(url: currentURL)
                .ignoresSafeArea()
        } else {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                ProgressView("Preparando SamVitals…")
            }
        }
    }

    private var menuButton: some View {
        Button(action: openDrawer) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(Color(red: 0.04, green: 0.32, blue: 0.43))
                .frame(width: 48, height: 48)
                .background(.regularMaterial)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.14), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Abrir menú de SamVitals")
    }

    private func handleSelection(_ item: NavigationItem) {
        guard item.isNavigable,
              let destination = destinationURL(for: item) else {
            navigationError = "La ruta seleccionada no es válida para este tenant."
            return
        }

        currentURL = destination
        closeDrawer()
    }

    private func openDrawer() {
        isDrawerOpen = true

        if navigationItems.isEmpty || navigationError != nil {
            Task { await loadNavigationItems(force: true) }
        }
    }

    private func closeDrawer() {
        isDrawerOpen = false
    }

    private func drawerWidth(for availableWidth: CGFloat) -> CGFloat {
        min(330, max(280, availableWidth * 0.44))
    }

    private func destinationURL(for item: NavigationItem) -> URL? {
        guard let route = item.route else { return nil }
        return routeResolver.destinationURL(for: route, relativeTo: initialURL)
    }

    private func reloadNavigationItems() {
        Task { await loadNavigationItems(force: true) }
    }

    @MainActor
    private func loadNavigationItems(force: Bool) async {
        guard !isLoadingNavigation else { return }
        guard force || navigationItems.isEmpty else { return }

        isLoadingNavigation = true
        navigationError = nil
        defer { isLoadingNavigation = false }

        do {
            navigationItems = try await navigationService.loadItems(for: initialURL)
        } catch {
            navigationError = error.localizedDescription
        }
    }

    @MainActor
    private func prepareAppCookie() async {
        guard let host = initialURL.host,
              let cookie = HTTPCookie(properties: [
                  .domain: host,
                  .path: "/",
                  .name: "samvitals_app",
                  .value: "app",
                  .secure: "TRUE",
                  .expires: Date().addingTimeInterval(60 * 60 * 24 * 365)
              ]) else {
            isAppCookieReady = true
            return
        }

        HTTPCookieStorage.shared.setCookie(cookie)

        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie) {
                continuation.resume()
            }
        }

        isAppCookieReady = true
    }
}

struct WebShellView_Previews: PreviewProvider {
    static var previews: some View {
        WebShellView(
            initialURL: URL(string: "https://demo.samvitals.com/login")!,
            navigationItems: [
                NavigationItem(
                    label: "Inicio",
                    icon: "home",
                    route: "/dashboard",
                    current: "tenant.dashboard"
                ),
                NavigationItem(
                    label: "Agenda",
                    icon: "calendar-days",
                    route: "/menu/agenda",
                    current: "agenda"
                )
            ]
        )
        .previewLayout(.fixed(width: 1_024, height: 768))
    }
}
