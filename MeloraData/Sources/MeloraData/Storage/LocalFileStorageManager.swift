import Foundation
import MeloraCore

#if canImport(CryptoKit)
import CryptoKit
#endif

/// Manages sandboxed file operations, streaming SHA-256 hashing, and disk quota verification.
public final class LocalFileStorageManager: FileStorageProtocol, @unchecked Sendable {
    public let baseStorageURL: URL
    public let tracksDirectoryURL: URL
    public let artworkDirectoryURL: URL

    private let fileManager: FileManager
    private let minimumFreeSpaceBufferBytes: Int64 = 10 * 1024 * 1024 // 10 MB safety buffer

    /// Initializes storage rooted at a base URL (defaults to Application Support/Melora).
    public init(
        baseStorageURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        if let customBase = baseStorageURL {
            self.baseStorageURL = customBase
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ??
                             URL(fileURLWithPath: NSTemporaryDirectory())
            self.baseStorageURL = appSupport.appendingPathComponent("Melora", isDirectory: true)
        }

        self.tracksDirectoryURL = self.baseStorageURL.appendingPathComponent("Tracks", isDirectory: true)
        self.artworkDirectoryURL = self.baseStorageURL.appendingPathComponent("Artwork", isDirectory: true)

        createDirectoriesIfNeeded()
    }

    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: tracksDirectoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: artworkDirectoryURL, withIntermediateDirectories: true)
    }

    // MARK: - FileStorageProtocol

    public func importAudioFile(from sourceURL: URL, preferredId: String) async throws -> (relativePath: String, fileSizeBytes: Int64) {
        let attributes = try? fileManager.attributesOfItem(atPath: sourceURL.path)
        let fileSizeBytes = (attributes?[.size] as? NSNumber)?.int64Value ?? 0

        guard fileSizeBytes > 0 else {
            throw StorageError.ioError(message: "Cannot import empty or unreadable audio file.")
        }

        // Verify available disk storage space
        try verifyAvailableStorageSpace(requiredBytes: fileSizeBytes)

        let ext = sourceURL.pathExtension.lowercased()
        let filename = "\(preferredId).\(ext)"
        let destinationURL = tracksDirectoryURL.appendingPathComponent(filename)

        // Remove destination if it already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw StorageError.ioError(message: "Failed to copy audio file into sandbox: \(error.localizedDescription)")
        }

        let relativePath = "Tracks/\(filename)"
        return (relativePath: relativePath, fileSizeBytes: fileSizeBytes)
    }

    /// Saves extracted album artwork data into the sandboxed Artwork directory.
    public func saveArtwork(data: Data, preferredId: String = UUID().uuidString) throws -> String {
        let filename = "\(preferredId).jpg"
        let destinationURL = artworkDirectoryURL.appendingPathComponent(filename)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try? fileManager.removeItem(at: destinationURL)
        }

        do {
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            throw StorageError.ioError(message: "Failed to write artwork thumbnail to disk: \(error.localizedDescription)")
        }

        return "Artwork/\(filename)"
    }

    public func resolveAbsoluteURL(forRelativePath relativePath: String) -> URL {
        let sanitized = (try? FileValidator.sanitizeRelativePath(relativePath)) ?? relativePath
        return baseStorageURL.appendingPathComponent(sanitized)
    }

    public func fileExists(atRelativePath relativePath: String) -> Bool {
        let absoluteURL = resolveAbsoluteURL(forRelativePath: relativePath)
        return fileManager.fileExists(atPath: absoluteURL.path)
    }

    /// Computes the SHA-256 hash using 64 KB chunked streaming to prevent memory spikes.
    public func computeFileHash(at url: URL) throws -> String {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw StorageError.fileNotFound(path: url.path)
        }
        defer { try? fileHandle.close() }

        let bufferSize = 65536 // 64 KB

        #if canImport(CryptoKit)
        var hasher = CryptoKit.SHA256()
        while let chunk = try? fileHandle.read(upToCount: bufferSize), !chunk.isEmpty {
            hasher.update(data: chunk)
        }
        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        // Portable stream hashing
        var fullData = Data()
        while let chunk = try? fileHandle.read(upToCount: bufferSize), !chunk.isEmpty {
            fullData.append(chunk)
        }
        let digest = PortableSHA256.hash(fullData)
        return digest.map { String(format: "%02x", $0) }.joined()
        #endif
    }

    /// Safely deletes a file from the sandbox, strictly preventing deletion outside sandbox boundaries.
    public func deleteFile(atRelativePath relativePath: String) throws {
        let sanitized = try FileValidator.sanitizeRelativePath(relativePath)
        let absoluteURL = baseStorageURL.appendingPathComponent(sanitized).standardizedFileURL

        // Security check: ensure target path is strictly within baseStorageURL
        let basePath = baseStorageURL.standardizedFileURL.path
        guard absoluteURL.path.hasPrefix(basePath) else {
            throw StorageError.pathTraversalAttempt(path: relativePath)
        }

        if fileManager.fileExists(atPath: absoluteURL.path) {
            try fileManager.removeItem(at: absoluteURL)
        }
    }

    /// Verifies that the host device has sufficient disk space for the file plus safety buffer.
    public func verifyAvailableStorageSpace(requiredBytes: Int64) throws {
        let path = baseStorageURL.path
        if let attrs = try? fileManager.attributesOfFileSystem(forPath: path),
           let freeSize = (attrs[.systemFreeSize] as? NSNumber)?.int64Value {
            let totalNeeded = requiredBytes + minimumFreeSpaceBufferBytes
            if freeSize < totalNeeded {
                throw StorageError.insufficientStorageSpace(requiredBytes: requiredBytes, availableBytes: freeSize)
            }
        }
    }
}
