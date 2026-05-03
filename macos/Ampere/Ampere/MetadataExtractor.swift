//
//  MetadataExtractor.swift
//  Ampere
//
//  Extract metadata and album art from audio files
//

import Foundation
import AVFoundation
import AppKit

struct AudioMetadata {
    var title: String?
    var artist: String?
    var album: String?
    /// Composer / writer (ID3 TCOM, common composer).
    var composer: String?
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    /// Beats per minute from tags when present (ID3 TBPM / iTunes BPM).
    var bpmFromTag: Double?
    var duration: Double?
    var albumArt: NSImage?
    var lyrics: String?
    var customTags: [String: String] = [:] // For ReplayGain and other custom tags
}

class MetadataExtractor {
    /// Parses "128", "128.5 BPM", etc.
    static func parseBPMString(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for word in trimmed.split(whereSeparator: { $0.isWhitespace || $0 == "," }) {
            let cleaned = String(word).filter { $0.isNumber || $0 == "." }
            if let v = Double(cleaned), v > 30, v < 400 { return v }
        }
        return nil
    }

    static func extractMetadata(from path: String) -> AudioMetadata {
        let url = URL(fileURLWithPath: path)
        let asset = AVURLAsset(url: url)
        
        var metadata = AudioMetadata()
        
        // Use async API with semaphore for synchronous access
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            do {
                // Load duration
                let duration = try await asset.load(.duration)
                let durationSeconds = CMTimeGetSeconds(duration)
                if !durationSeconds.isNaN && durationSeconds.isFinite && durationSeconds > 0 {
                    metadata.duration = durationSeconds
                }
                
                // Load available metadata formats
                let formats = try await asset.load(.availableMetadataFormats)
                
                // Extract metadata from all available formats
                for format in formats {
                    let metadataItems = try await asset.loadMetadata(for: format)
                    for item in metadataItems {
                        switch item.commonKey {
                        case .commonKeyTitle:
                            metadata.title = try? await item.load(.stringValue)
                        case .commonKeyArtist:
                            metadata.artist = try? await item.load(.stringValue)
                        case .commonKeyAlbumName:
                            metadata.album = try? await item.load(.stringValue)
                        case .commonKeyType:
                            metadata.genre = try? await item.load(.stringValue)
                        case .commonKeyCreationDate:
                            if let dateString = try? await item.load(.stringValue) {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy"
                                if let date = formatter.date(from: dateString) {
                                    let calendar = Calendar.current
                                    metadata.year = calendar.component(.year, from: date)
                                }
                            }
                        case .commonKeyArtwork:
                            if let data = try? await item.load(.dataValue), let image = NSImage(data: data) {
                                metadata.albumArt = image
                            }
                        default:
                            break
                        }
                    }
                }
                
                // Lyrics, ReplayGain, BPM from tags, and extra ID3 keys
                for format in formats {
                    let metadataItems = try await asset.loadMetadata(for: format)
                    for item in metadataItems {
                        if let key = item.key as? String, (key == "USLT" || key == "lyrics") {
                            metadata.lyrics = try? await item.load(.stringValue)
                        }
                        
                        // Extract ReplayGain tags
                        if let key = item.key as? String {
                            if key == "REPLAYGAIN_TRACK_GAIN" || key == "replaygain_track_gain" {
                                if let value = try? await item.load(.stringValue) {
                                    metadata.customTags["REPLAYGAIN_TRACK_GAIN"] = value
                                }
                            }
                            if key == "REPLAYGAIN_ALBUM_GAIN" || key == "replaygain_album_gain" {
                                if let value = try? await item.load(.stringValue) {
                                    metadata.customTags["REPLAYGAIN_ALBUM_GAIN"] = value
                                }
                            }
                        }

                        let idRaw = item.identifier?.rawValue.lowercased() ?? ""
                        if idRaw.contains("tbpm") || idRaw.contains("bpm") || idRaw.contains("beats") || idRaw.hasSuffix("/tmpo") {
                            if metadata.bpmFromTag == nil, let str = try? await item.load(.stringValue), let bpm = Self.parseBPMString(str) {
                                metadata.bpmFromTag = bpm
                            }
                        }
                        if metadata.composer == nil,
                           idRaw.contains("tcom") || idRaw.contains("composer"),
                           let c = try? await item.load(.stringValue), !c.isEmpty {
                            metadata.composer = c
                        }
                        if metadata.composer == nil,
                           let ck = item.commonKey?.rawValue.lowercased(),
                           ck.contains("composer"),
                           let c = try? await item.load(.stringValue), !c.isEmpty {
                            metadata.composer = c
                        }
                    }
                }
            } catch {
                print("Failed to extract metadata: \(error)")
            }
            
            semaphore.signal()
        }
        
        // Wait for async operation to complete (with timeout)
        _ = semaphore.wait(timeout: .now() + 5.0)
        
        return metadata
    }
}

