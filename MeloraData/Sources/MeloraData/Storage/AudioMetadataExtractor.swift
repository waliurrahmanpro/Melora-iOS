import Foundation
import MeloraCore

#if canImport(AVFoundation)
import AVFoundation
#endif

/// Extracted audio metadata values from an audio file.
public struct ExtractedAudioMetadata: Sendable {
    public let title: String
    public let artistName: String
    public let albumTitle: String?
    public let durationMs: Int
    public let bitrate: Int?
    public let sampleRate: Int?
    public let channels: Int
    public let artworkData: Data?
    public let artworkMimeType: String?

    public init(
        title: String,
        artistName: String,
        albumTitle: String? = nil,
        durationMs: Int,
        bitrate: Int? = nil,
        sampleRate: Int? = nil,
        channels: Int = 2,
        artworkData: Data? = nil,
        artworkMimeType: String? = nil
    ) {
        self.title = title
        self.artistName = artistName
        self.albumTitle = albumTitle
        self.durationMs = durationMs
        self.bitrate = bitrate
        self.sampleRate = sampleRate
        self.channels = channels
        self.artworkData = artworkData
        self.artworkMimeType = artworkMimeType
    }
}

/// Abstract contract for reading audio metadata from local files.
public protocol AudioMetadataExtractorProtocol: Sendable {
    func extractMetadata(from fileURL: URL, audioFormat: AudioFormat) async throws -> ExtractedAudioMetadata
}

/// Metadata extractor utilizing AVFoundation on Apple platforms with a cross-platform tag fallback.
public final class AudioMetadataExtractor: AudioMetadataExtractorProtocol, @unchecked Sendable {

    public init() {}

    public func extractMetadata(from fileURL: URL, audioFormat: AudioFormat) async throws -> ExtractedAudioMetadata {
        #if canImport(AVFoundation)
        return try await extractUsingAVFoundation(from: fileURL, audioFormat: audioFormat)
        #else
        return extractUsingFallback(from: fileURL, audioFormat: audioFormat)
        #endif
    }

    #if canImport(AVFoundation)
    private func extractUsingAVFoundation(from fileURL: URL, audioFormat: AudioFormat) async throws -> ExtractedAudioMetadata {
        let asset = AVURLAsset(url: fileURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])

        // Modern iOS 16/18 async metadata loading
        let durationCMTime = (try? await asset.load(.duration)) ?? .zero
        let durationSeconds = CMTimeGetSeconds(durationCMTime)
        let durationMs = durationSeconds.isFinite && durationSeconds > 0 ? Int(durationSeconds * 1000.0) : 0

        var extractedTitle: String?
        var extractedArtist: String?
        var extractedAlbum: String?
        var extractedArtwork: Data?
        var artworkMime: String?

        if let metadataItems = try? await asset.load(.metadata) {
            for item in metadataItems {
                guard let key = item.commonKey?.rawValue ?? item.keyString else { continue }
                let lowerKey = key.lowercased()

                if lowerKey == "title" && extractedTitle == nil {
                    extractedTitle = try? await item.load(.stringValue)
                } else if (lowerKey == "artist" || lowerKey == "author") && extractedArtist == nil {
                    extractedArtist = try? await item.load(.stringValue)
                } else if (lowerKey == "albumname" || lowerKey == "album") && extractedAlbum == nil {
                    extractedAlbum = try? await item.load(.stringValue)
                } else if lowerKey == "artwork" && extractedArtwork == nil {
                    if let data = try? await item.load(.dataValue) {
                        extractedArtwork = data
                        artworkMime = "image/jpeg"
                    }
                }
            }
        }

        // Audio track inspection for sample rate, bitrate, and channels
        var sampleRate: Int?
        var channels: Int = 2
        var bitrate: Int?

        if let tracks = try? await asset.loadTracks(withMediaType: .audio), let audioTrack = tracks.first {
            let descArray = (try? await audioTrack.load(.formatDescriptions)) ?? []
            for desc in descArray {
                if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(desc)?.pointee {
                    if asbd.mSampleRate > 0 {
                        sampleRate = Int(asbd.mSampleRate)
                    }
                    if asbd.mChannelsPerFrame > 0 {
                        channels = Int(asbd.mChannelsPerFrame)
                    }
                }
            }
            if let estimatedRate = try? await audioTrack.load(.estimatedDataRate), estimatedRate > 0 {
                bitrate = Int(estimatedRate)
            }
        }

        // Clean fallbacks for missing metadata
        let fallbackTitle = fileURL.deletingPathExtension().lastPathComponent
        let finalTitle = (extractedTitle?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ?
            extractedTitle! : fallbackTitle
        let finalArtist = (extractedArtist?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false) ?
            extractedArtist! : "Unknown Artist"

        return ExtractedAudioMetadata(
            title: finalTitle,
            artistName: finalArtist,
            albumTitle: extractedAlbum,
            durationMs: durationMs,
            bitrate: bitrate,
            sampleRate: sampleRate,
            channels: channels,
            artworkData: extractedArtwork,
            artworkMimeType: artworkMime
        )
    }
    #endif

    /// Cross-platform fallback parser that inspects ID3v2 headers or derives tags from filename.
    public func extractUsingFallback(from fileURL: URL, audioFormat: AudioFormat) -> ExtractedAudioMetadata {
        var title: String?
        var artist: String?
        var album: String?

        // Attempt basic ID3 tag extraction if reading an MP3 file
        if let handle = try? FileHandle(forReadingFrom: fileURL) {
            defer { try? handle.close() }
            if let header = try? handle.read(upToCount: 128) {
                let bytes = [UInt8](header)
                if bytes.count >= 10 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33 {
                    // ID3v2 tag detected - read frame tags if available
                    if let stringData = String(data: header, encoding: .isoLatin1) {
                        if let tIndex = stringData.range(of: "TIT2") {
                            title = extractID3Text(from: stringData, after: tIndex.upperBound)
                        }
                        if let aIndex = stringData.range(of: "TPE1") {
                            artist = extractID3Text(from: stringData, after: aIndex.upperBound)
                        }
                        if let albIndex = stringData.range(of: "TALB") {
                            album = extractID3Text(from: stringData, after: albIndex.upperBound)
                        }
                    }
                }
            }
        }

        let filename = fileURL.deletingPathExtension().lastPathComponent
        let finalTitle = title ?? filename
        let finalArtist = artist ?? "Unknown Artist"

        return ExtractedAudioMetadata(
            title: finalTitle,
            artistName: finalArtist,
            albumTitle: album,
            durationMs: 180000, // 3 min default when native duration decoder is unavailable
            bitrate: 320000,
            sampleRate: 44100,
            channels: 2,
            artworkData: nil,
            artworkMimeType: nil
        )
    }

    private func extractID3Text(from string: String, after index: String.Index) -> String? {
        let remainder = string[index...]
        let cleaned = remainder.prefix(60).trimmingCharacters(in: CharacterSet.controlCharacters.union(.whitespacesAndNewlines))
        return cleaned.isEmpty ? nil : cleaned
    }
}

#if canImport(AVFoundation)
private extension AVMetadataItem {
    var keyString: String? {
        if let keyStr = key as? String {
            return keyStr
        }
        if let num = key as? NSNumber {
            return num.stringValue
        }
        return nil
    }
}
#endif
