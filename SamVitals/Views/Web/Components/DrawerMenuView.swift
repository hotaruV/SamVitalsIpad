import SwiftUI

struct DrawerMenuView: View {
    let items: [NavigationItem]
    let isLoading: Bool
    let errorMessage: String?
    let onSelect: (NavigationItem) -> Void
    let onRetry: () -> Void
    let onClose: () -> Void
    let onChangeTenant: () -> Void

    @State private var expandedItemIDs: Set<String> = []

    init(
        items: [NavigationItem],
        isLoading: Bool = false,
        errorMessage: String? = nil,
        onSelect: @escaping (NavigationItem) -> Void,
        onRetry: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {},
        onChangeTenant: @escaping () -> Void = {}
    ) {
        self.items = items
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.onSelect = onSelect
        self.onRetry = onRetry
        self.onClose = onClose
        self.onChangeTenant = onChangeTenant
        _expandedItemIDs = State(
            initialValue: Set(
                items
                    .filter(\.isExpandable)
                    .map(\.id)
            )
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            menuContent

            Divider()

            Button(action: onChangeTenant) {
                Label("Cambiar SamVitals ID", systemImage: "arrow.left.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(red: 0.27, green: 0.35, blue: 0.48))
            .accessibilityHint("Regresa a la selección de clínica o consultorio")
        }
        .background(Color(.systemBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Menú de SamVitals")
    }

    @ViewBuilder
    private var menuContent: some View {
        if isLoading {
            Spacer()
            ProgressView("Cargando menú…")
            Spacer()
        } else if let errorMessage {
            Spacer()
            ContentUnavailableView {
                Label("Menú no disponible", systemImage: "list.bullet.rectangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Intentar de nuevo", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            Spacer()
        } else if items.isEmpty {
            Spacer()
            ContentUnavailableView(
                "Menú no disponible",
                systemImage: "list.bullet.rectangle",
                description: Text("Inicia sesión y vuelve a abrir el menú.")
            )
            .padding()
            Spacer()
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    Text("MENÚ")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(Color(red: 0.48, green: 0.56, blue: 0.68))
                        .padding(.horizontal, 12)
                        .padding(.bottom, 8)

                    ForEach(items) { item in
                        DrawerNavigationRow(
                            item: item,
                            depth: 0,
                            expandedItemIDs: $expandedItemIDs,
                            onSelect: onSelect
                        )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var header: some View {
        HStack(spacing: 13) {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(Color(red: 0.92, green: 1, blue: 0.98))
                .frame(width: 58, height: 58)
                .overlay {
                    Image("LogoSam")
                        .resizable()
                        .scaledToFit()
                        .padding(5)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text("SAMVITALS")
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.18))

                Text("Tu espacio clínico")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 38, height: 38)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cerrar menú")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }
}

private struct DrawerNavigationRow: View {
    let item: NavigationItem
    let depth: Int
    @Binding var expandedItemIDs: Set<String>
    let onSelect: (NavigationItem) -> Void

    private var isExpanded: Bool {
        expandedItemIDs.contains(item.id)
    }

    var body: some View {
        Group {
            if item.isExpandable {
                expandableGroup
            } else {
                navigationButton
            }
        }
    }

    private var navigationButton: some View {
        Button(action: handleTap) {
            rowLabel
                .padding(.leading, CGFloat(depth) * 12)
                .padding(.horizontal, 10)
                .frame(minHeight: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.label)
        .accessibilityHint(accessibilityHint)
    }

    private var expandableGroup: some View {
        VStack(spacing: 2) {
            Button(action: handleTap) {
                rowLabel
                    .padding(.horizontal, 10)
                    .frame(minHeight: 42)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.label)
            .accessibilityHint(accessibilityHint)
            .accessibilityValue(isExpanded ? "Expandido" : "Contraído")

            if isExpanded {
                VStack(spacing: 1) {
                    ForEach(item.subitems) { subitem in
                        DrawerNavigationRow(
                            item: subitem,
                            depth: depth + 1,
                            expandedItemIDs: $expandedItemIDs,
                            onSelect: onSelect
                        )
                    }
                }
                .padding(.leading, 12)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 0.82, green: 0.87, blue: 0.92))
                        .frame(width: 1)
                        .padding(.vertical, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(4)
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 0.84, green: 0.88, blue: 0.93), lineWidth: 1)
        }
        .padding(.vertical, 3)
    }

    private var rowLabel: some View {
        HStack(spacing: 11) {
            Image(systemName: NavigationIconMapper.systemName(for: item.icon))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(red: 0.38, green: 0.48, blue: 0.62))
                .frame(width: 24, height: 24)

            Text(item.label)
                .font(.system(size: 15, weight: depth == 0 ? .medium : .regular))
                .foregroundStyle(Color(red: 0.27, green: 0.35, blue: 0.48))
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.isExpandable {
                Image(systemName: "chevron.up")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.60, green: 0.68, blue: 0.78))
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
            }
        }
    }

    private var accessibilityHint: String {
        if item.isExpandable {
            return isExpanded ? "Colapsa el grupo" : "Expande el grupo"
        }

        return item.isNavigable ? "Abre esta sección" : "Elemento no disponible"
    }

    private func handleTap() {
        if item.isExpandable {
            withAnimation(.easeInOut(duration: 0.2)) {
                if isExpanded {
                    expandedItemIDs.remove(item.id)
                } else {
                    expandedItemIDs.insert(item.id)
                }
            }
        } else if item.isNavigable {
            onSelect(item)
        }
    }
}

struct DrawerMenuView_Previews: PreviewProvider {
    static var previews: some View {
        DrawerMenuView(
            items: [
                NavigationItem(
                    label: "Inicio",
                    icon: "home",
                    route: "/dashboard",
                    current: "tenant.dashboard"
                ),
                NavigationItem(
                    label: "Configuración",
                    icon: "cog-6-tooth",
                    subitems: [
                        NavigationItem(
                            label: "Servicios",
                            icon: "adjustments-horizontal",
                            route: "/administracion/servicios"
                        ),
                        NavigationItem(
                            label: "Usuarios",
                            icon: "users",
                            route: "/administracion/servicios/usuarios/operativos"
                        )
                    ]
                )
            ],
            onSelect: { _ in }
        )
        .frame(width: 360)
        .previewLayout(.fixed(width: 360, height: 900))
    }
}
