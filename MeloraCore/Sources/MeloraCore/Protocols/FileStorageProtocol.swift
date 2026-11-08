import Foundation

/// Abstract contract for sandboxed audio file storage operations.
public protocol FileStorageProtocol: Sendable {
    /// Sandboxed base directory where Melora audio files are stored.
    var baseStorageURL: URL { get }

    /// Ingests an external audio file into the local sandbox, generating a unique relative path.
    func importAudioFile(from sourceURL: URL, preferredId: String) async throws -> (relativePath: String, fileSizeBytes: Int64)

    /// Resolves a stored relative path (e.g. "Tracks/abc-123.flac") to a playable absolute file URL.
    func resolveAbsoluteURL(forRelativePath relativePath: String) -> URL

    /// Checks if a file exists at the given relative path.
    func fileExists(atRelativePath relativePath: String) -> Bool

    /// Computes the SHA-256 hash of a file to detect duplicates during import.
    func computeFileHash(at url: URL) throws -> String

    /// Deletes a file from the sandbox when its corresponding track is removed.
    func deleteFile(atRelativePath relativePath: String) throws
}
