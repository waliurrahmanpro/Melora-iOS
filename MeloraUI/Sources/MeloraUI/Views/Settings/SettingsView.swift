import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Screen 08 — Settings: Audio playback options, history cleaner, and application information.
public struct SettingsView: View {
    @Bindable public var viewModel: SettingsViewModel

    public init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Audio Behavior Section
                Section(header: Text("Audio & Playback").foregroundColor(MeloraColors.textSecondary)) {
                    Toggle("Pause on Headphone Disconnect", isOn: $viewModel.pauseOnDisconnect)
                        .tint(MeloraColors.accent)

                    Toggle("Auto-Advance to Next Track", isOn: $viewModel.autoAdvance)
                        .tint(MeloraColors.accent)
                }
                .listRowBackground(MeloraColors.darkCard)

                // Library & History Management
                Section(header: Text("History & Privacy").foregroundColor(MeloraColors.textSecondary)) {
                    Button(role: .destructive, action: {
                        viewModel.clearListeningHistory()
                    }) {
                        HStack {
                            Text("Clear Playback History")
                            Spacer()
                            if viewModel.isHistoryCleared {
                                Image(systemName: "checkmark")
                                    .foregroundColor(MeloraColors.success)
                            }
                        }
                    }
                }
                .listRowBackground(MeloraColors.darkCard)

                // Spotify Integration Status
                Section(header: Text("Connected Services").foregroundColor(MeloraColors.textSecondary)) {
                    HStack {
                        Image(systemName: "wave.3.forward.circle.fill")
                            .foregroundColor(MeloraColors.spotifyGreen)
                        Text("Spotify Web API")
                            .font(MeloraTypography.bodyRegular)
                        Spacer()
                        Text(viewModel.isSpotifyConnected ? "Connected" : "Disconnected")
                            .font(MeloraTypography.captionMedium)
                            .foregroundColor(viewModel.isSpotifyConnected ? MeloraColors.spotifyGreen : MeloraColors.textTertiary)
                    }
                }
                .listRowBackground(MeloraColors.darkCard)

                // About Section
                Section(header: Text("About Melora").foregroundColor(MeloraColors.textSecondary)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Build 2026.11)")
                            .foregroundColor(MeloraColors.textSecondary)
                    }

                    HStack {
                        Text("Target Architecture")
                        Spacer()
                        Text("Native iOS 18+ • Swift 6")
                            .foregroundColor(MeloraColors.textSecondary)
                    }

                    HStack {
                        Text("Audio Engine")
                        Spacer()
                        Text("AVFoundation • SQLite")
                            .foregroundColor(MeloraColors.textSecondary)
                    }

                    HStack {
                        Text("Functional Reference")
                        Spacer()
                        Text("ArchiveTune (rukamori)")
                            .foregroundColor(MeloraColors.textSecondary)
                    }
                }
                .listRowBackground(MeloraColors.darkCard)
            }
            .scrollContentBackground(.hidden)
            .meloraBackground()
            .navigationTitle("Settings")
        }
    }
}
#endif
