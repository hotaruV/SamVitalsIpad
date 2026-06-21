import SwiftUI

struct AccessCard: View {
    @Binding var samVitalsID: String
    @Binding var rememberSamVitalsID: Bool
    let metrics: LayoutMetrics
    let isResolving: Bool
    let errorMessage: String?
    let rememberAction: () -> Void
    let action: () -> Void

    private var normalizedSamVitalsID: String {
        samVitalsID.normalizedSamVitalsID
    }

    private var samVitalsIDBinding: Binding<String> {
        Binding(
            get: { samVitalsID },
            set: { samVitalsID = $0.samVitalsIDInput }
        )
    }

    var body: some View {
        ZStack(alignment: metrics.usesColumns ? .topTrailing : .top) {
            VStack(alignment: .leading, spacing: metrics.isCompact ? 16 : 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Acceso clientes")
                        .font(.system(size: metrics.isCompact ? 30 : 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.06, green: 0.09, blue: 0.18))
                    Text("Escribe el nombre que aparece antes de .samvitals.com")
                        .font(.system(size: metrics.isCompact ? 13 : 15))
                        .foregroundStyle(Color(red: 0.45, green: 0.52, blue: 0.64))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("NOMBRE DE TU CLÍNICA O CONSULTORIO")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(Color(red: 0.41, green: 0.48, blue: 0.62))

                    HStack(spacing: 0) {
                        TextField("doctor-martinez", text: samVitalsIDBinding)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .font(.system(size: metrics.isCompact ? 18 : 21, weight: .bold))
                            .padding(.horizontal, 14)
                            .frame(height: metrics.fieldHeight)
                            .background(.white)
                            .submitLabel(.go)
                            .onSubmit(submit)

                        Text(".samvitals.com")
                            .font(.system(size: metrics.isCompact ? 14 : 16, weight: .bold))
                            .foregroundStyle(Color(red: 0.02, green: 0.38, blue: 0.54))
                            .padding(.horizontal, metrics.isCompact ? 10 : 14)
                            .frame(height: metrics.fieldHeight)
                            .background(Color(red: 0.90, green: 1.0, blue: 1.0))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
                    }

                    Text("Escribe únicamente Tu SAMVITALS ID")
                        .font(.system(size: metrics.isCompact ? 11 : 13))
                        .foregroundStyle(Color(red: 0.45, green: 0.52, blue: 0.64))
                        .lineLimit(2)

                    Button(action: rememberAction) {
                        Label {
                            Text("Recordar SamVitals ID")
                        } icon: {
                            Image(systemName: rememberSamVitalsID ? "checkmark.square.fill" : "square")
                                .foregroundStyle(
                                    rememberSamVitalsID
                                        ? Color(red: 0.10, green: 0.67, blue: 0.60)
                                        : Color.secondary
                                )
                        }
                        .font(.system(size: metrics.isCompact ? 12 : 14, weight: .semibold))
                        .foregroundStyle(Color(red: 0.16, green: 0.25, blue: 0.38))
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(rememberSamVitalsID ? "Activado" : "Desactivado")

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .font(.system(size: metrics.isCompact ? 11 : 13, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                }

                Button(action: submit) {
                    HStack(spacing: 9) {
                        if isResolving {
                            ProgressView()
                                .tint(.white)
                            Text("Validando…")
                        } else {
                            Image(systemName: "arrow.right.to.line.compact")
                            Text("Entrar a mi panel")
                        }
                    }
                    .font(.system(size: metrics.isCompact ? 19 : 21, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: metrics.isCompact ? 58 : 66)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.10, green: 0.67, blue: 0.60))
                .disabled(normalizedSamVitalsID.isEmpty || isResolving)
                .opacity(normalizedSamVitalsID.isEmpty || isResolving ? 0.55 : 1)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color(red: 0.10, green: 0.67, blue: 0.60).opacity(0.25), radius: 14, x: 0, y: 10)

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Color(red: 0.02, green: 0.48, blue: 0.62))
                    Text("Este acceso es solo para clientes de SamVitals. Si todavía no tienes uno, solicita información y te ayudamos a configurar tu espacio.")
                        .font(.system(size: metrics.isCompact ? 11 : 13))
                        .foregroundStyle(Color(red: 0.16, green: 0.38, blue: 0.49))
                        .lineSpacing(2)
                }
                .padding(metrics.isCompact ? 13 : 16)
                .background(Color(red: 0.90, green: 1.0, blue: 1.0).opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color.cyan.opacity(0.24), lineWidth: 1)
                }
            }
            .frame(maxWidth: metrics.usesColumns ? .infinity : 620)
            .padding(metrics.cardPadding)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: metrics.isCompact ? 26 : 30, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: metrics.isCompact ? 26 : 30, style: .continuous)
                    .stroke(Color.cyan.opacity(0.26), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 28, x: 0, y: 20)

            Image(systemName: "person.badge.key.fill")
                .font(.system(size: metrics.isCompact ? 24 : 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: metrics.isCompact ? 54 : 62, height: metrics.isCompact ? 54 : 62)
                .background(Color(red: 0.10, green: 0.67, blue: 0.60))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color(red: 0.10, green: 0.67, blue: 0.60).opacity(0.35), radius: 16, x: 0, y: 10)
                .offset(
                    x: metrics.usesColumns ? (metrics.isCompact ? 8 : 14) : 0,
                    y: metrics.isCompact ? -18 : -24
                )
        }
        .padding(.top, metrics.isCompact ? 18 : 24)
        .padding(.trailing, metrics.usesColumns ? (metrics.isCompact ? 8 : 14) : 0)
    }

    private func submit() {
        samVitalsID = normalizedSamVitalsID
        guard !samVitalsID.isEmpty, !isResolving else { return }
        action()
    }
}
