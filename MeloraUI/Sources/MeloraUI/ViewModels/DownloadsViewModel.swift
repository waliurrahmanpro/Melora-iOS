import Foundation
import MeloraCore
import MeloraData

#if canImport(Observation)
import Observation
#endif

@Observable
public final class DownloadsViewModel: @unchecked Sendable {
    public let trackRepository: TrackRepositoryProtocol
    public let filterService: LibraryFilterService
    public let storageManager: LocalFileStorageManager

    public var tracks: [Track] = []
    public var totalStorageBytes: Int64 = 0
    public var formatUsageBreakdown: [AudioFormat: Int64] = [:]

    public init(
        trackRepository: TrackRepositoryProtocol,
        filterService: LibraryFilterService,
        storageManager: LocalFileStorageManager
    ) {
        self.trackRepository = trackRepository
        self.filterService = filterService
        self.storageManager = storageManager
    }

    public var totalStorageFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageBytes)
    }

    public func loadData() {
        do {
            let all = try trackRepository.getAllTracks()
            self.tracks = all
            self.totalStorageBytes = all.reduce(0) { $0 + $1.fileSizeBytes }

            var breakdown: [AudioFormat: Int64] = [:]
            for track in all {
                breakdown[track.audioFormat, default: 0] += track.fileSizeBytes
            }
            self.formatUsageBreakdown = breakdown
        } catch {}
    }

    public func deleteTrack(_ track: Track) {
        try? filterService.safelyDeleteTrack(track)
        loadData()
    }
}
