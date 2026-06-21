import SwiftUI

struct FooterView: View {
    var body: some View {
        VStack(spacing: 4) {
            ViewThatFits {
                HStack(spacing: 10) {
                    Text("Políticas de privacidad")
                    Text("•")
                    Text("Términos y condiciones")
                    Text("•")
                    Text("SamVitals para iPad")
                }

                VStack(spacing: 3) {
                    Text("Políticas de privacidad  •  Términos y condiciones")
                    Text("SamVitals para iPad")
                }
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(.secondary)

            Text("© 2026 SamVitals. Aplicación nativa para iPadOS.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 6)
    }
}
