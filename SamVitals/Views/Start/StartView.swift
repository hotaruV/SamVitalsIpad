import SwiftUI

struct StartView: View {
    @Binding var samVitalsID: String
    @Binding var rememberSamVitalsID: Bool
    let isResolving: Bool
    let errorMessage: String?
    let rememberAction: () -> Void
    let action: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let metrics = LayoutMetrics(size: geometry.size)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.91, green: 1.0, blue: 0.98),
                        Color(red: 0.97, green: 0.99, blue: 1.0),
                        Color(red: 0.93, green: 0.96, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: metrics.sectionSpacing) {
                        Group {
                            if metrics.usesColumns {
                                HStack(alignment: .center, spacing: metrics.columnSpacing) {
                                    HeroSection(metrics: metrics)
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    AccessCard(
                                    samVitalsID: $samVitalsID,
                                    rememberSamVitalsID: $rememberSamVitalsID,
                                    metrics: metrics,
                                    isResolving: isResolving,
                                    errorMessage: errorMessage,
                                    rememberAction: rememberAction,
                                    action: action
                                    )
                                    .frame(width: metrics.formWidth)
                                }
                            } else {
                                VStack(spacing: metrics.sectionSpacing) {
                                    HeroSection(metrics: metrics)

                                    AccessCard(
                                        samVitalsID: $samVitalsID,
                                        rememberSamVitalsID: $rememberSamVitalsID,
                                        metrics: metrics,
                                        isResolving: isResolving,
                                        errorMessage: errorMessage,
                                        rememberAction: rememberAction,
                                        action: action
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                            }
                        }
                        .frame(maxHeight: .infinity, alignment: .center)

                        FooterView()
                    }
                    .frame(
                        minHeight: max(
                            0,
                            geometry.size.height - metrics.verticalPadding - 16
                        )
                    )
                    .frame(maxWidth: metrics.contentWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, metrics.verticalPadding)
                    .padding(.bottom, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
    }
}
