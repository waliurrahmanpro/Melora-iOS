import Foundation

/// Errors related to audio file validation, storage, and sandboxed ingestion.
public enum StorageError: Error, LocalizedError, Equatable, Sendable {
    case fileNotFound(path: String)
    case duplicateFile(hash: String, existingTrackTitle: String)
    case unsupportedFormat(extensionName: String)
    case invalidFileSignature(expected: String, actual: String)
    case pathTraversalAttempt(path: String)
    case securityScopeAccessFailed(url: URL)
    case insufficientStorageSpace(requiredBytes: Int64, availableBytes: Int64)
    case ioError(message: String)
    case metadataExtractionFailed(message: String)
    case importCancelled

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found at path: \(path)"
        case .duplicateFile(_, let title):
            return "Audio file is already in your library ('\(title)')."
        case .unsupportedFormat(let ext):
            return "Unsupported audio format: '.\(ext)'. Melora supports MP3, M4A, AAC, FLAC, WAV, and AIFF."
        case .invalidFileSignature(let expected, let actual):
            return "Invalid file content signature. Expected '\(expected)', detected '\(actual)'. File may be corrupted or renamed."
        case .pathTraversalAttempt(let path):
            return "Path traversal security violation for path: '\(path)'."
        case .securityScopeAccessFailed(let url):
            return "Failed to acquire security-scoped access for file: \(url.lastPathComponent)."
        case .insufficientStorageSpace(let req, let avail):
            let reqMB = Double(req) / (1024 * 1024)
            let availMB = Double(avail) / (1024 * 1024)
            return String(format: "Insufficient storage space. Required: %.1f MB, Available: %.1f MB", reqMB, availMB)
        case .ioError(let msg):
            return "File I/O error: \(msg)"
        case .metadataExtractionFailed(let msg):
            return "Failed to extract audio metadata: \(msg)"
        case .importCancelled:
            return "Audio file import was cancelled by the user."
        }
    }
}
