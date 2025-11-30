//
//  SpatialAudio3D.swift
//  Ampere
//
//  3D Spatial Audio Settings
//

import Foundation
import AVFoundation
import Combine

class SpatialAudio3D: ObservableObject {
    @Published var enabled: Bool = false
    @Published var azimuth: Float = 0.0 // -180 to 180 degrees
    @Published var elevation: Float = 0.0 // -90 to 90 degrees
    @Published var distance: Float = 1.0 // 0.0 to 1.0
    @Published var reverbBlend: Float = 0.0 // 0.0 to 1.0
    
    @Published var surroundMode: SurroundMode = .stereo
    @Published var spatializationQuality: SpatializationQuality = .high
    
    enum SurroundMode: String, CaseIterable {
        case stereo = "Stereo"
        case quad = "Quad"
        case surround51 = "5.1 Surround"
        case surround71 = "7.1 Surround"
        case ambisonic = "Ambisonic"
    }
    
    enum SpatializationQuality: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }
    
    private var audioEngine: AVAudioEngine?
    private var spatialAudioNode: AVAudioEnvironmentNode?
    
    func setupSpatialAudio(audioEngine: AVAudioEngine) {
        self.audioEngine = audioEngine
        
        // Create environment node for 3D audio
        let environmentNode = AVAudioEnvironmentNode()
        environmentNode.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environmentNode.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)
        
        audioEngine.attach(environmentNode)
        self.spatialAudioNode = environmentNode
    }
    
    func updateSpatialSettings() {
        guard let node = spatialAudioNode else { return }
        
        // Convert azimuth/elevation to 3D position
        let azimuthRad = azimuth * .pi / 180.0
        let elevationRad = elevation * .pi / 180.0
        
        let x = distance * cos(elevationRad) * sin(azimuthRad)
        let y = distance * sin(elevationRad)
        let z = distance * cos(elevationRad) * cos(azimuthRad)
        
        // Update listener position (inverse for source)
        node.listenerPosition = AVAudio3DPoint(x: -x, y: -y, z: -z)
        node.reverbBlend = reverbBlend
    }
    
    func getEnvironmentNode() -> AVAudioEnvironmentNode? {
        return spatialAudioNode
    }
}

