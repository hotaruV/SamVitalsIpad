import SwiftUI
import WebKit

struct WebShellView: View {
    let initialURL: URL
    let onChangeTenant: () -> Void

    @State private var navigationRequest: WebNavigationRequest
    @State private var visibleURL: URL
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
        navigationService: MobileNavigationService? = nil,
        onChangeTenant: @escaping () -> Void = {}
    ) {
        self.initialURL = initialURL
        self.onChangeTenant = onChangeTenant
        self.navigationService = navigationService ?? MobileNavigationService()
        _navigationRequest = State(
            initialValue: WebNavigationRequest(destination: initialURL)
        )
        _visibleURL = State(initialValue: initialURL)
        _navigationItems = State(initialValue: navigationItems)
    }

    private var isPublicAccessScreen: Bool {
        WebRouteVisibility.isPublicAccessURL(visibleURL)
    }

    private var isLoginScreen: Bool {
        WebRouteVisibility.isLoginURL(visibleURL)
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                loginChromeBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    loginHeader
                        .frame(height: isLoginScreen ? 58 : 0)
                        .opacity(isLoginScreen ? 1 : 0)
                        .clipped()
                        .allowsHitTesting(isLoginScreen)

                    webContent
                        .ignoresSafeArea(edges: isLoginScreen ? [] : .all)

                    loginFooter
                        .padding(
                            .bottom,
                            isLoginScreen ? max(geometry.safeAreaInsets.bottom, 12) : 0
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(height: isLoginScreen ? nil : 0)
                        .opacity(isLoginScreen ? 1 : 0)
                        .clipped()
                        .allowsHitTesting(isLoginScreen)
                }

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
                        onClose: closeDrawer,
                        onChangeTenant: changeTenant
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
                if !isDrawerOpen && !isPublicAccessScreen {
                    menuButton
                        .padding(.leading, 16)
                        .padding(.top, geometry.safeAreaInsets.top + 35)
                }
            }
        }
        .animation(.easeInOut(duration: 0.24), value: isDrawerOpen)
        .task(id: initialURL) {
            await prepareAppCookie()
        }
    }

    @ViewBuilder
    private var webContent: some View {
        if isAppCookieReady {
            SamVitalsWebView(
                url: navigationRequest.destination,
                navigationRequestID: navigationRequest.id,
                onURLChange: handleURLChange
            )
        } else {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                ProgressView("Preparando SamVitals…")
            }
        }
    }

    private var loginHeader: some View {
        HStack {
            changeTenantButton
            Spacer()
        }
        .padding(.horizontal, 16)
        .background(.clear)
        .accessibilityElement(children: .contain)
    }

    private var loginFooter: some View {
        FooterView()
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
        .background(.clear)
    }

    private var loginChromeBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.99, blue: 1.0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
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

    private var changeTenantButton: some View {
        Button(action: changeTenant) {
            Label("Cambiar SamVitals ID", systemImage: "chevron.left")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(red: 0.04, green: 0.32, blue: 0.43))
                .padding(.horizontal, 14)
                .frame(height: 42)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityHint("Regresa a la pantalla para elegir clínica o consultorio")
    }

    private func handleSelection(_ item: NavigationItem) {
        guard item.isNavigable,
              let destination = destinationURL(for: item) else {
            navigationError = "La ruta seleccionada no es válida para este tenant."
            return
        }

        navigationRequest = WebNavigationRequest(destination: destination)
        closeDrawer()
    }

    private func openDrawer() {
        guard !isPublicAccessScreen else { return }
        isDrawerOpen = true

        if navigationItems.isEmpty || navigationError != nil {
            Task { await loadNavigationItems(force: true) }
        }
    }

    private func closeDrawer() {
        isDrawerOpen = false
    }

    private func changeTenant() {
        closeDrawer()
        onChangeTenant()
    }

    private func handleURLChange(_ url: URL) {
        guard url.host?.lowercased() == initialURL.host?.lowercased() else { return }
        visibleURL = url

        if WebRouteVisibility.isPublicAccessURL(url) {
            closeDrawer()
            navigationItems = []
            navigationError = nil
        } else if navigationItems.isEmpty {
            Task { await loadNavigationItems(force: false) }
        }
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
            let loadedItems = try await navigationService.loadItems(for: initialURL)
            guard !isPublicAccessScreen else { return }
            navigationItems = loadedItems
        } catch {
            guard !isPublicAccessScreen else { return }
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

private struct WebNavigationRequest: Equatable {
    let id = UUID()
    let destination: URL
}

enum WebRouteVisibility {
    static func isLoginURL(_ url: URL) -> Bool {
        normalizedPath(for: url) == "login"
    }

    static func isPublicAccessURL(_ url: URL) -> Bool {
        let path = normalizedPath(for: url)

        return path.isEmpty ||
            path == "login" ||
            path == "register" ||
            path == "forgot-password" ||
            path == "reset-password" ||
            path.hasPrefix("reset-password/") ||
            path == "email/verify" ||
            path.hasPrefix("email/verify/")
    }

    private static func normalizedPath(for url: URL) -> String {
        url.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
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
