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
    var genre: String?
    var year: Int?
    var trackNumber: Int?
    var duration: Double?
    var albumArt: NSImage?
    var lyrics: String?
}

class MetadataExtractor {
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
                
                // Try to extract lyrics from metadata
                for format in formats {
                    let metadataItems = try await asset.loadMetadata(for: format)
                    for item in metadataItems {
                        if let key = item.key as? String, (key == "USLT" || key == "lyrics") {
                            metadata.lyrics = try? await item.load(.stringValue)
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

