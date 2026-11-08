import Foundation
import MeloraCore
import MeloraData

#if canImport(Observation)
import Observation
#endif

public enum LibrarySegment: String, CaseIterable, Identifiable, Sendable {
    case songs = "Songs"
    case artists = "Artists"
    case albums = "Albums"
    case recentlyAdded = "Recent"

    public var id: String { rawValue }
}

@Observable
public final class LibraryViewModel: @unchecked Sendable {
    public let trackRepository: TrackRepositoryProtocol
    public let importService: LibraryImportService
    public let filterService: LibraryFilterService

    public var selectedSegment: LibrarySegment = .songs
    public var sortOption: TrackSortOption = .titleAscending
    public var selectedFormatFilter: AudioFormat?

    public var allTracks: [Track] = []
    public var filteredTracks: [Track] = []
    public var artists: [String] = []
    public var albums: [String] = []

    public var isImporting: Bool = false
    public var importProgress: ImportProgress?
    public var isFilePickerPresented: Bool = false
    public var statusMessage: String?

    public init(
        trackRepository: TrackRepositoryProtocol,
        importService: LibraryImportService,
        filterService: LibraryFilterService
    ) {
        self.trackRepository = trackRepository
        self.importService = importService
        self.filterService = filterService
    }

    public var totalTracksCount: Int {
        allTracks.count
    }

    public var totalLibraryDurationFormatted: String {
        let totalMs = allTracks.reduce(0) { $0 + $1.durationMs }
        let hours = totalMs / 3600000
        let minutes = (totalMs % 3600000) / 60000
        return hours > 0 ? "\(hours) hr \(minutes) min" : "\(minutes) min"
    }

    public func loadLibrary() {
        do {
            let tracks = try trackRepository.getAllTracks()
            self.allTracks = tracks
            self.artists = Array(Set(tracks.map { $0.artistName })).sorted()
            self.albums = Array(Set(tracks.compactMap { $0.albumTitle })).sorted()
            applyFilterAndSort()
        } catch {
            self.statusMessage = "Error loading library: \(error.localizedDescription)"
        }
    }

    public func applyFilterAndSort() {
        var result = allTracks

        if let format = selectedFormatFilter {
            result = filterService.filterTracks(tracks: result, audioFormat: format)
        }

        result = filterService.sortTracks(result, by: sortOption)
        self.filteredTracks = result
    }

    public func importAudioFiles(urls: [URL]) {
        self.isImporting = true
        self.importProgress = ImportProgress(currentFilename: "Preparing...", processedCount: 0, totalCount: urls.count)

        Task {
            do {
                let summary = try await importService.importAudioFiles(from: urls) { progress in
                    Task { @MainActor in
                        self.importProgress = progress
                    }
                }
                await MainActor.run {
                    self.isImporting = false
                    self.loadLibrary()
                    self.statusMessage = "Imported \(summary.importedTracks.count) new tracks."
                }
            } catch {
                await MainActor.run {
                    self.isImporting = false
                    self.statusMessage = "Import failed: \(error.localizedDescription)"
                }
            }
        }
    }

    public func deleteTrack(_ track: Track) {
        do {
            try filterService.safelyDeleteTrack(track)
            loadLibrary()
        } catch {
            self.statusMessage = "Failed to delete track: \(error.localizedDescription)"
        }
    }
}
