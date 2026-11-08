import Foundation
import MeloraCore

/// Real-time progress snapshot during batch file ingestion.
public struct ImportProgress: Sendable, Equatable {
    public let currentFilename: String
    public let processedCount: Int
    public let totalCount: Int
    public let isCancelled: Bool

    public var percentage: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(processedCount) / Double(totalCount)
    }

    public init(currentFilename: String, processedCount: Int, totalCount: Int, isCancelled: Bool = false) {
        self.currentFilename = currentFilename
        self.processedCount = processedCount
        self.totalCount = totalCount
        self.isCancelled = isCancelled
    }
}

/// Consolidated result summary from a batch audio import session.
public struct ImportResult: Sendable {
    public let importedTracks: [Track]
    public let duplicateCount: Int
    public let failedFiles: [(url: URL, error: String)]

    public init(
        importedTracks: [Track] = [],
        duplicateCount: Int = 0,
        failedFiles: [(url: URL, error: String)] = []
    ) {
        self.importedTracks = importedTracks
        self.duplicateCount = duplicateCount
        self.failedFiles = failedFiles
    }
}

/// Orchestrates validation, sandboxed storage, metadata extraction, duplicate prevention, and atomic database persistence.
public final class LibraryImportService: @unchecked Sendable {
    private let storageManager: LocalFileStorageManager
    private let metadataExtractor: AudioMetadataExtractorProtocol
    private let trackRepository: TrackRepositoryProtocol
    private let fileImporter: AudioFileImporter

    private let lock = NSLock()
    private var isCancelled: Bool = false

    public init(
        storageManager: LocalFileStorageManager,
        metadataExtractor: AudioMetadataExtractorProtocol = AudioMetadataExtractor(),
        trackRepository: TrackRepositoryProtocol,
        fileImporter: AudioFileImporter = AudioFileImporter()
    ) {
        self.storageManager = storageManager
        self.metadataExtractor = metadataExtractor
        self.trackRepository = trackRepository
        self.fileImporter = fileImporter
    }

    /// Signals cancellation of an active batch import operation.
    public func cancel() {
        lock.lock()
        self.isCancelled = true
        lock.unlock()
    }

    /// Resets the cancellation flag.
    public func resetCancellation() {
        lock.lock()
        self.isCancelled = false
        lock.unlock()
    }

    private var checkCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }

    /// Ingests a collection of external audio files into the Melora sandbox and library database.
    ///
    /// - Parameters:
    ///   - fileURLs: External audio file URLs selected by the user.
    ///   - onProgress: Optional closure receiving step-by-step progress updates.
    /// - Returns: Consolidated `ImportResult`.
    public func importAudioFiles(
        from fileURLs: [URL],
        onProgress: ((ImportProgress) -> Void)? = nil
    ) async throws -> ImportResult {
        resetCancellation()

        var importedTracks: [Track] = []
        var newlyCreatedRelativePaths: [String] = []
        var duplicateCount = 0
        var failedFiles: [(url: URL, error: String)] = []

        let total = fileURLs.count

        for (index, url) in fileURLs.enumerated() {
            if checkCancelled || Task.isCancelled {
                // Clean up any files copied so far before throwing
                cleanupOrphanedFiles(paths: newlyCreatedRelativePaths)
                throw StorageError.importCancelled
            }

            onProgress?(ImportProgress(
                currentFilename: url.lastPathComponent,
                processedCount: index,
                totalCount: total
            ))

            do {
                let track = try await fileImporter.accessSecurityScopedFileAsync(at: url) { securedURL in
                    return try await self.processSingleFile(
                        at: securedURL,
                        newlyCreatedPaths: &newlyCreatedRelativePaths
                    )
                }

                if let validTrack = track {
                    importedTracks.append(validTrack)
                } else {
                    duplicateCount += 1
                }
            } catch let err as StorageError {
                switch err {
                case .duplicateFile:
                    duplicateCount += 1
                default:
                    failedFiles.append((url: url, error: err.localizedDescription))
                }
            } catch {
                failedFiles.append((url: url, error: error.localizedDescription))
            }
        }

        // Commit tracks to database atomically
        if !importedTracks.isEmpty {
            do {
                try trackRepository.insertTracks(importedTracks)
            } catch {
                // Database failed: clean up all copied files immediately
                cleanupOrphanedFiles(paths: newlyCreatedRelativePaths)
                throw StorageError.ioError(message: "Database insertion failed: \(error.localizedDescription). Sandbox files cleaned up.")
            }
        }

        onProgress?(ImportProgress(
            currentFilename: "Completed",
            processedCount: total,
            totalCount: total
        ))

        return ImportResult(
            importedTracks: importedTracks,
            duplicateCount: duplicateCount,
            failedFiles: failedFiles
        )
    }

    // MARK: - Single File Processing

    private func processSingleFile(
        at url: URL,
        newlyCreatedPaths: inout [String]
    ) async throws -> Track? {
        // 1. Validate format extension and magic bytes
        let format = try FileValidator.validateExtension(of: url)
        try FileValidator.validateMagicBytes(at: url, expectedFormat: format)

        // 2. Compute streaming SHA-256 hash for duplicate check
        let fileHash = try storageManager.computeFileHash(at: url)

        // 3. Query repository for existing duplicate
        if let existing = try trackRepository.getTrackByFileHash(fileHash) {
            throw StorageError.duplicateFile(hash: fileHash, existingTrackTitle: existing.title)
        }

        // 4. Generate unique track identifier
        let trackId = UUID().uuidString

        // 5. Copy file into sandbox Tracks/
        let (relativePath, sizeBytes) = try await storageManager.importAudioFile(from: url, preferredId: trackId)
        newlyCreatedPaths.append(relativePath)

        let sandboxedFileURL = storageManager.resolveAbsoluteURL(forRelativePath: relativePath)

        // 6. Extract metadata
        let metadata = try await metadataExtractor.extractMetadata(from: sandboxedFileURL, audioFormat: format)

        // 7. Save artwork if present
        var artworkRelativePath: String? = nil
        if let artworkData = metadata.artworkData {
            if let savedPath = try? storageManager.saveArtwork(data: artworkData, preferredId: trackId) {
                artworkRelativePath = savedPath
                newlyCreatedPaths.append(savedPath)
            }
        }

        // 8. Construct Track entity
        return Track(
            id: trackId,
            title: metadata.title,
            artistName: metadata.artistName,
            albumTitle: metadata.albumTitle,
            durationMs: metadata.durationMs,
            filePath: relativePath,
            fileSizeBytes: sizeBytes,
            audioFormat: format,
            bitrate: metadata.bitrate,
            sampleRate: metadata.sampleRate,
            channels: metadata.channels,
            spotifyId: nil,
            artworkPath: artworkRelativePath,
            fileHash: fileHash,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Deletes newly created physical files if an import operation fails or rolls back.
    private func cleanupOrphanedFiles(paths: [String]) {
        for path in paths {
            try? storageManager.deleteFile(atRelativePath: path)
        }
    }
}
