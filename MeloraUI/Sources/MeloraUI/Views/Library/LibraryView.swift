import Foundation
import MeloraCore

#if canImport(SwiftUI)
import SwiftUI

/// Screen 04 — Library: Full local collection with sorting, format filters, and Document Picker importing.
public struct LibraryView: View {
    @Bindable public var viewModel: LibraryViewModel
    @Bindable public var playerViewModel: PlayerViewModel

    public init(viewModel: LibraryViewModel, playerViewModel: PlayerViewModel) {
        self.viewModel = viewModel
        self.playerViewModel = playerViewModel
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: MeloraSpacing.md) {
                // Segment Picker
                Picker("Library Segment", selection: $viewModel.selectedSegment) {
                    ForEach(LibrarySegment.allCases) { seg in
                        Text(seg.rawValue).tag(seg)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MeloraSpacing.lg)

                // Stats & Sort Toolbar
                HStack {
                    Text("\(viewModel.totalTracksCount) songs • \(viewModel.totalLibraryDurationFormatted)")
                        .font(MeloraTypography.caption)
                        .foregroundColor(MeloraColors.textSecondary)

                    Spacer()

                    // Sort Menu
                    Menu {
                        Button("Title (A-Z)") { viewModel.sortOption = .titleAscending; viewModel.applyFilterAndSort() }
                        Button("Title (Z-A)") { viewModel.sortOption = .titleDescending; viewModel.applyFilterAndSort() }
                        Button("Artist (A-Z)") { viewModel.sortOption = .artistAscending; viewModel.applyFilterAndSort() }
                        Button("Duration (Shortest)") { viewModel.sortOption = .durationShortest; viewModel.applyFilterAndSort() }
                        Button("Date Added (Newest)") { viewModel.sortOption = .dateAddedNewest; viewModel.applyFilterAndSort() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text("Sort")
                        }
                        .font(MeloraTypography.captionMedium)
                        .foregroundColor(MeloraColors.accent)
                    }
                }
                .padding(.horizontal, MeloraSpacing.lg)

                // Audio Format Filter Pills
                formatFilterRow

                // Segment Content
                if viewModel.allTracks.isEmpty {
                    MeloraEmptyState(
                        systemImage: "folder.badge.plus",
                        title: "No Songs in Library",
                        message: "Import your legally acquired audio files (MP3, FLAC, M4A, WAV, AIFF) to start listening.",
                        buttonTitle: "Import Audio Files"
                    ) {
                        viewModel.isFilePickerPresented = true
                    }
                } else {
                    contentList
                }
            }
            .meloraBackground()
            .navigationTitle("Your Library")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.isFilePickerPresented = true }) {
                        Label("Import", systemImage: "plus")
                            .font(MeloraTypography.bodyBold)
                            .foregroundColor(MeloraColors.accent)
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button(action: { viewModel.isFilePickerPresented = true }) {
                        Label("Import", systemImage: "plus")
                            .font(MeloraTypography.bodyBold)
                            .foregroundColor(MeloraColors.accent)
                    }
                }
                #endif
            }
            .onAppear {
                viewModel.loadLibrary()
            }
            .fileImporter(
                isPresented: $viewModel.isFilePickerPresented,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    viewModel.importAudioFiles(urls: urls)
                case .failure:
                    break
                }
            }
            .overlay {
                if viewModel.isImporting, let progress = viewModel.importProgress {
                    importProgressHUD(progress: progress)
                }
            }
        }
    }

    // MARK: - Subviews

    private var formatFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MeloraSpacing.xs) {
                Button(action: {
                    viewModel.selectedFormatFilter = nil
                    viewModel.applyFilterAndSort()
                }) {
                    Text("All Formats")
                        .font(MeloraTypography.badge)
                        .foregroundColor(viewModel.selectedFormatFilter == nil ? MeloraColors.textPrimary : MeloraColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(viewModel.selectedFormatFilter == nil ? MeloraColors.accent : MeloraColors.cardElevated)
                        .clipShape(Capsule())
                }

                ForEach(AudioFormat.allCases, id: \.self) { format in
                    Button(action: {
                        viewModel.selectedFormatFilter = format
                        viewModel.applyFilterAndSort()
                    }) {
                        Text(format.rawValue.uppercased())
                            .font(MeloraTypography.badge)
                            .foregroundColor(viewModel.selectedFormatFilter == format ? MeloraColors.textPrimary : MeloraColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(viewModel.selectedFormatFilter == format ? MeloraColors.accent : MeloraColors.cardElevated)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, MeloraSpacing.lg)
        }
    }

    private var contentList: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: MeloraSpacing.xs) {
                switch viewModel.selectedSegment {
                case .songs, .recentlyAdded:
                    ForEach(viewModel.filteredTracks) { track in
                        MeloraTrackRow(
                            track: track,
                            isPlaying: track.id == playerViewModel.currentTrack?.id,
                            onPlay: {
                                playerViewModel.playTrack(track, queue: viewModel.filteredTracks)
                            },
                            onMoreAction: {
                                viewModel.deleteTrack(track)
                            }
                        )
                    }

                case .artists:
                    ForEach(viewModel.artists, id: \.self) { artist in
                        HStack(spacing: MeloraSpacing.md) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(MeloraColors.accent)
                            Text(artist)
                                .font(MeloraTypography.bodyBold)
                                .foregroundColor(MeloraColors.textPrimary)
                            Spacer()
                        }
                        .padding(.vertical, MeloraSpacing.sm)
                    }

                case .albums:
                    ForEach(viewModel.albums, id: \.self) { album in
                        HStack(spacing: MeloraSpacing.md) {
                            Image(systemName: "square.stack.fill")
                                .font(.system(size: 28))
                                .foregroundColor(MeloraColors.accent)
                            Text(album)
                                .font(MeloraTypography.bodyBold)
                                .foregroundColor(MeloraColors.textPrimary)
                            Spacer()
                        }
                        .padding(.vertical, MeloraSpacing.sm)
                    }
                }
            }
            .padding(.horizontal, MeloraSpacing.lg)
            .padding(.bottom, 100)
        }
    }

    private func importProgressHUD(progress: ImportProgress) -> some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: MeloraSpacing.md) {
                ProgressView()
                    .tint(MeloraColors.accent)
                    .scaleEffect(1.2)

                Text("Importing Audio Files")
                    .font(MeloraTypography.bodyBold)
                    .foregroundColor(MeloraColors.textPrimary)

                Text(progress.currentFilename)
                    .font(MeloraTypography.caption)
                    .foregroundColor(MeloraColors.textSecondary)
                    .lineLimit(1)

                ProgressView(value: progress.percentage)
                    .tint(MeloraColors.accent)
                    .frame(width: 200)

                Text("\(progress.processedCount) of \(progress.totalCount)")
                    .font(MeloraTypography.caption)
                    .foregroundColor(MeloraColors.textTertiary)
            }
            .padding(MeloraSpacing.xl)
            .background(MeloraColors.cardElevated)
            .clipShape(RoundedRectangle(cornerRadius: MeloraSpacing.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: MeloraSpacing.radiusCard, style: .continuous)
                    .stroke(MeloraColors.cardBorder, lineWidth: 1)
            )
        }
    }
}
#endif
