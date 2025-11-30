//
//  ChannelSettings.swift
//  Ampere
//
//  Channel configuration (Stereo, Mono, Surround)
//

import Foundation
import AVFoundation
import Combine

enum ChannelMode: String, CaseIterable {
    case stereo = "Stereo"
    case mono = "Mono"
    case surround = "Surround"
}

class ChannelSettings: ObservableObject {
    @Published var channelMode: ChannelMode = .stereo
    @Published var balance: Float = 0.0 // -1.0 (left) to 1.0 (right)
    @Published var leftVolume: Float = 1.0
    @Published var rightVolume: Float = 1.0
    
    func applyToPlayer(_ player: AVPlayer) {
        // Apply channel settings to AVPlayer
        // Note: AVPlayer has limited channel control, may need AVAudioEngine for advanced features
    }
}

