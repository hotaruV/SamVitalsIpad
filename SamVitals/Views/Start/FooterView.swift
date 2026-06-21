import SwiftUI

struct FooterView: View {
    private let privacyURL = URL(string: "https://samvitals.com/privacy")!
    private let termsURL = URL(string: "https://samvitals.com/terms")!

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        VStack(spacing: 3) {
            ViewThatFits {
                HStack(spacing: 10) {
                    privacyLink
                    separator
                    termsLink
                    separator
                    biometricExplanation
                }

                VStack(spacing: 3) {
                    HStack(spacing: 10) {
                        privacyLink
                        separator
                        termsLink
                    }
                    biometricExplanation
                }
            }

            Text("© 2026 SamVitals · App para iPadOS · Versión \(appVersion)")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color(red: 0.40, green: 0.48, blue: 0.58))
        }
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(Color(red: 0.12, green: 0.32, blue: 0.43))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 18)
        .padding(.vertical, 5)
        .frame(maxWidth: 760)
        .background(.clear)
    }

    private var privacyLink: some View {
        Link(destination: privacyURL) {
            Label("Privacidad", systemImage: "hand.raised.fill")
        }
        .accessibilityHint("Abre la política de privacidad en Safari")
    }

    private var termsLink: some View {
        Link(destination: termsURL) {
            Label("Términos y condiciones", systemImage: "doc.text.fill")
        }
        .accessibilityHint("Abre los términos y condiciones en Safari")
    }

    private var biometricExplanation: some View {
        Label(
            "Face ID o Touch ID protege el acceso guardado; la biometría se valida únicamente en iPadOS.",
            systemImage: "lock.shield.fill"
        )
        .fontWeight(.medium)
        .lineLimit(1)
        .minimumScaleFactor(0.85)
        .accessibilityElement(children: .combine)
    }

    private var separator: some View {
        Text("•")
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}
