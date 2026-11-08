import Foundation
import MeloraCore

/// Security and media integrity validator for imported audio files.
public enum FileValidator {

    /// Validates that a file's extension matches a supported Melora audio format.
    public static func validateExtension(of url: URL) throws -> AudioFormat {
        let ext = url.pathExtension.lowercased()
        guard let format = AudioFormat(fileExtension: ext) else {
            throw StorageError.unsupportedFormat(extensionName: ext)
        }
        return format
    }

    /// Inspects initial magic bytes of the file to verify actual media container contents.
    ///
    /// Reads only the first 16 bytes, preventing memory bloat on large files.
    public static func validateMagicBytes(at url: URL, expectedFormat: AudioFormat) throws {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else {
            throw StorageError.fileNotFound(path: url.path)
        }
        defer { try? fileHandle.close() }

        guard let headerData = try? fileHandle.read(upToCount: 16), headerData.count >= 4 else {
            throw StorageError.invalidFileSignature(expected: expectedFormat.rawValue, actual: "Empty or truncated header")
        }

        let bytes = [UInt8](headerData)

        switch expectedFormat {
        case .flac:
            // "fLaC" = 0x66 0x4C 0x61 0x43
            if bytes.count >= 4 && bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43 {
                return
            }
            throw StorageError.invalidFileSignature(expected: "fLaC", actual: hexString(prefix: bytes, count: 4))

        case .mp3:
            // ID3 tag header ("ID3" = 0x49 0x44 0x33) or MPEG sync frame (0xFF 0xFB, 0xFF 0xF3, 0xFF 0xF2, 0xFF 0xE3)
            if bytes.count >= 3 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33 {
                return
            }
            if bytes.count >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0 {
                return
            }
            throw StorageError.invalidFileSignature(expected: "ID3 or MPEG Frame Sync", actual: hexString(prefix: bytes, count: 4))

        case .wav:
            // "RIFF" header with "WAVE" format identifier
            if bytes.count >= 12 &&
               bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
               bytes[8] == 0x57 && bytes[9] == 0x41 && bytes[10] == 0x56 && bytes[11] == 0x45 {
                return
            }
            throw StorageError.invalidFileSignature(expected: "RIFF/WAVE", actual: hexString(prefix: bytes, count: 4))

        case .aiff:
            // "FORM" header with "AIFF" or "AIFC" format identifier
            if bytes.count >= 12 &&
               bytes[0] == 0x46 && bytes[1] == 0x4F && bytes[2] == 0x52 && bytes[3] == 0x4D &&
               bytes[8] == 0x41 && bytes[9] == 0x49 && bytes[10] == 0x46 {
                return
            }
            throw StorageError.invalidFileSignature(expected: "FORM/AIFF", actual: hexString(prefix: bytes, count: 4))

        case .m4a, .alac:
            // MP4 container: bytes 4..7 are "ftyp" (0x66 0x74 0x79 0x70)
            if bytes.count >= 8 && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
                return
            }
            throw StorageError.invalidFileSignature(expected: "ftyp (MP4 Container)", actual: hexString(prefix: bytes, count: 8))

        case .aac:
            // Either MP4 container ("ftyp") or ADTS stream header (0xFF 0xF1 or 0xFF 0xF9)
            if bytes.count >= 8 && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
                return
            }
            if bytes.count >= 2 && bytes[0] == 0xFF && (bytes[1] & 0xF6) == 0xF0 {
                return
            }
            throw StorageError.invalidFileSignature(expected: "ADTS Sync or ftyp", actual: hexString(prefix: bytes, count: 4))
        }
    }

    /// Validates a relative file path against directory traversal attempts.
    public static func sanitizeRelativePath(_ relativePath: String) throws -> String {
        if relativePath.hasPrefix("/") || relativePath.hasPrefix("\\") || relativePath.contains("..") || relativePath.contains("\0") {
            throw StorageError.pathTraversalAttempt(path: relativePath)
        }

        let cleaned = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/\\ "))
        guard !cleaned.isEmpty else {
            throw StorageError.pathTraversalAttempt(path: relativePath)
        }

        return cleaned
    }

    private static func hexString(prefix: [UInt8], count: Int) -> String {
        let slice = prefix.prefix(count)
        return slice.map { String(format: "%02X", $0) }.joined(separator: " ")
    }
}
