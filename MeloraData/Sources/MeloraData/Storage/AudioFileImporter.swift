import Foundation
import MeloraCore

/// Handles security-scoped document picker file access and batch file validation.
public final class AudioFileImporter: Sendable {

    public init() {}

    /// Executes an operation on a security-scoped URL, ensuring safe acquisition and release.
    public func accessSecurityScopedFile<T>(at url: URL, operation: (URL) throws -> T) throws -> T {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try operation(url)
    }

    /// Asynchronous variant of security-scoped resource access.
    public func accessSecurityScopedFileAsync<T>(at url: URL, operation: (URL) async throws -> T) async throws -> T {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        return try await operation(url)
    }

    /// Filters and validates a list of external URLs, returning valid audio files ready for ingestion.
    public func validateImportCandidates(urls: [URL]) -> (valid: [(url: URL, format: AudioFormat)], invalid: [(url: URL, error: StorageError)]) {
        var valid: [(url: URL, format: AudioFormat)] = []
        var invalid: [(url: URL, error: StorageError)] = []

        for url in urls {
            do {
                let format = try FileValidator.validateExtension(of: url)
                valid.append((url: url, format: format))
            } catch let err as StorageError {
                invalid.append((url: url, error: err))
            } catch {
                invalid.append((url: url, error: .ioError(message: error.localizedDescription)))
            }
        }

        return (valid: valid, invalid: invalid)
    }
}
