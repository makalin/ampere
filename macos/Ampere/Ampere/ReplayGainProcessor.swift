//
//  ReplayGainProcessor.swift
//  Ampere
//
//  ReplayGain support for audio normalization
//

import Foundation
import AVFoundation
import Combine

enum ReplayGainMode {
    case off
    case track    // Use track gain
    case album    // Use album gain
    case auto     // Auto-detect best mode
}

class ReplayGainProcessor: ObservableObject {
    @Published var mode: ReplayGainMode = .off
    @Published var preAmp: Double = 0.0 // dB adjustment
    
    private let targetLoudness: Double = -23.0 // EBU R128 standard (-23 LUFS)
    private var trackGain: Double? = nil
    private var albumGain: Double? = nil
    
    init() {
        // Load settings from UserDefaults
        if let savedMode = UserDefaults.standard.string(forKey: "ReplayGainMode"),
           let modeValue = ReplayGainMode(rawValue: savedMode) {
            mode = modeValue
        }
        if let savedPreAmp = UserDefaults.standard.object(forKey: "ReplayGainPreAmp") as? Double {
            preAmp = savedPreAmp
        }
    }
    
    func setMode(_ newMode: ReplayGainMode) {
        mode = newMode
        UserDefaults.standard.set(newMode.rawValue, forKey: "ReplayGainMode")
    }
    
    func setPreAmp(_ value: Double) {
        preAmp = max(-20.0, min(20.0, value)) // Clamp between -20 to +20 dB
        UserDefaults.standard.set(preAmp, forKey: "ReplayGainPreAmp")
    }
    
    func extractReplayGain(from metadata: AudioMetadata) {
        // Try to extract ReplayGain tags from metadata
        // Common tags: REPLAYGAIN_TRACK_GAIN, REPLAYGAIN_ALBUM_GAIN
        if let trackGainString = metadata.customTags["REPLAYGAIN_TRACK_GAIN"] {
            trackGain = parseGainString(trackGainString)
        }
        if let albumGainString = metadata.customTags["REPLAYGAIN_ALBUM_GAIN"] {
            albumGain = parseGainString(albumGainString)
        }
    }
    
    private func parseGainString(_ string: String) -> Double? {
        // Parse format like "0.5 dB" or "-2.3 dB"
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        if let dbValue = Double(trimmed.replacingOccurrences(of: " dB", with: "")) {
            return dbValue
        }
        return nil
    }
    
    func calculateVolumeAdjustment() -> Float {
        guard mode != .off else {
            return 1.0 // No adjustment
        }
        
        var gain: Double? = nil
        
        switch mode {
        case .off:
            return 1.0
        case .track:
            gain = trackGain
        case .album:
            gain = albumGain
        case .auto:
            // Prefer album gain, fall back to track gain
            gain = albumGain ?? trackGain
        }
        
        guard let gainValue = gain else {
            return 1.0 // No gain data available
        }
        
        // Calculate volume adjustment: gain + preAmp
        let totalGain = gainValue + preAmp
        
        // Convert dB to linear volume (0.0 to 1.0)
        // Volume = 10^(gain/20)
        let linearVolume = pow(10.0, totalGain / 20.0)
        
        // Clamp to safe range (0.0 to 2.0, then normalize to 0.0-1.0)
        let clampedVolume = max(0.0, min(2.0, linearVolume))
        return Float(clampedVolume)
    }
    
    func reset() {
        trackGain = nil
        albumGain = nil
    }
}

extension ReplayGainMode {
    var rawValue: String {
        switch self {
        case .off: return "off"
        case .track: return "track"
        case .album: return "album"
        case .auto: return "auto"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "off": self = .off
        case "track": self = .track
        case "album": self = .album
        case "auto": self = .auto
        default: return nil
        }
    }
}

