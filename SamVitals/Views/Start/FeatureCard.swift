import SwiftUI

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let metrics: LayoutMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: metrics.isCompact ? 8 : 11) {
            Image(systemName: icon)
                .font(.system(size: metrics.isCompact ? 20 : 23, weight: .bold))
                .foregroundStyle(Color(red: 0.02, green: 0.48, blue: 0.62))
                .frame(width: metrics.isCompact ? 38 : 44, height: metrics.isCompact ? 38 : 44)
                .background(Color(red: 0.90, green: 1.0, blue: 1.0))
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            Text(title)
                .font(.system(size: metrics.isCompact ? 14 : 17, weight: .bold))
                .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.22))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(description)
                .font(.system(size: metrics.isCompact ? 12 : 14))
                .foregroundStyle(Color(red: 0.40, green: 0.48, blue: 0.61))
                .lineLimit(3)
                .minimumScaleFactor(0.8)
        }
        .padding(metrics.isCompact ? 14 : 18)
        .frame(maxWidth: .infinity, minHeight: metrics.featureHeight, alignment: .topLeading)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: metrics.isCompact ? 18 : 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: metrics.isCompact ? 18 : 22, style: .continuous)
                .stroke(Color.cyan.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 8)
    }
}
