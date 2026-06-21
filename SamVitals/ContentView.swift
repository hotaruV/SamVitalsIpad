//
//  ContentView.swift
//  SamVitals
//
//  Created by CarlosV on 19/06/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = StartViewModel()

    var body: some View {
        Group {
            if viewModel.isRestoringSession {
                SessionPrivacyLockView(
                    errorMessage: viewModel.sessionUnlockError,
                    retry: {
                        Task { await viewModel.restoreSessionIfNeeded() }
                    },
                    useAnotherTenant: viewModel.forgetStoredSession
                )
            } else if let loginURL = viewModel.loginURL {
                WebShellView(initialURL: loginURL)
            } else {
                StartView(
                    samVitalsID: $viewModel.samVitalsID,
                    rememberSamVitalsID: $viewModel.rememberSamVitalsID,
                    isResolving: viewModel.isResolving,
                    errorMessage: viewModel.errorMessage,
                    rememberAction: viewModel.toggleRememberSamVitalsID,
                    action: {
                        Task { await viewModel.resolve() }
                    }
                )
            }
        }
        .task { await viewModel.restoreSessionIfNeeded() }
    }
}

private struct SessionPrivacyLockView: View {
    let errorMessage: String?
    let retry: () -> Void
    let useAnotherTenant: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if let errorMessage {
                ContentUnavailableView {
                    Label("SamVitals está bloqueado", systemImage: "lock.shield.fill")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button("Intentar de nuevo", action: retry)
                        .buttonStyle(.borderedProminent)
                    Button("Usar otro SamVitals ID", action: useAnotherTenant)
                }
            } else {
                ProgressView("Desbloqueando SamVitals…")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDisplayName("iPad Pro 13 portrait")
                .previewLayout(.fixed(width: 1_024, height: 1_366))

            ContentView()
                .previewDisplayName("iPad mini portrait")
                .previewLayout(.fixed(width: 744, height: 1_133))

            ContentView()
                .previewDisplayName("iPad mini landscape")
                .previewLayout(.fixed(width: 1_133, height: 744))
        }
    }
}
