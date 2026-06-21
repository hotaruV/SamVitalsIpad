import SwiftUI

struct HeroSection: View {
    let metrics: LayoutMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.isCompact ? 20 : 28) {
            brand
            securityBadge

            VStack(alignment: .leading, spacing: 12) {
                Text("Entra al panel de tu consultorio")
                    .font(.system(size: metrics.titleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.18))
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text("Escribe el nombre de acceso que te asignamos y te llevaremos directo al espacio privado de tu clínica o consultorio.")
                    .font(.system(size: metrics.bodySize))
                    .foregroundStyle(Color(red: 0.31, green: 0.39, blue: 0.52))
                    .lineSpacing(4)
                    .frame(maxWidth: 650, alignment: .leading)
            }

            HStack(spacing: metrics.isCompact ? 12 : 16) {
                FeatureCard(
                    icon: "building.2.crop.circle.fill",
                    title: "Tu espacio",
                    description: "Cada clínica tiene su propio acceso privado.",
                    metrics: metrics
                )
                FeatureCard(
                    icon: "key.fill",
                    title: "Fácil de usar",
                    description: "Solo escribe el nombre que te compartieron.",
                    metrics: metrics
                )
                FeatureCard(
                    icon: "headphones.circle.fill",
                    title: "¿Necesitas ayuda?",
                    description: "Si no sabes tu acceso, pídelo a tu administrador.",
                    metrics: metrics
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var brand: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: metrics.isCompact ? 16 : 20, style: .continuous)
                .fill(.white.opacity(0.85))
                .frame(width: metrics.logoSize, height: metrics.logoSize)
                .overlay {
                    Image("LogoSam")
                        .resizable()
                        .scaledToFit()
                        .padding(6)
                }
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text("SAMVITALS")
                    .font(.system(size: metrics.isCompact ? 22 : 26, weight: .black, design: .rounded))
                Text("Plataforma clínica inteligente")
                    .font(.system(size: metrics.isCompact ? 12 : 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var securityBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 14, weight: .bold))
            Text("Acceso seguro para clientes")
                .font(.system(size: metrics.isCompact ? 14 : 16, weight: .semibold))
        }
        .foregroundStyle(Color(red: 0.02, green: 0.35, blue: 0.50))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.white.opacity(0.82))
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color.cyan.opacity(0.28), lineWidth: 1) }
    }
}
