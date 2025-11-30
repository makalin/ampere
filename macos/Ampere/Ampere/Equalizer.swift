//
//  Equalizer.swift
//  Ampere
//
//  10-band Equalizer using AVAudioEngine
//

import Foundation
import AVFoundation

class Equalizer {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var eqUnit: AVAudioUnitEQ?
    private var bands: [AVAudioUnitEQFilterParameters] = []
    private var enabled: Bool = true
    
    // Dedicated serial queue for audio engine operations to avoid priority inversion
    private let audioQueue = DispatchQueue(label: "com.ampere.equalizer.audio", qos: .userInitiated)
    
    private let bandFrequencies: [Float] = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    
    init() {
        setupEqualizer()
    }
    
    private func setupEqualizer() {
        // Perform AVAudioEngine operations on background queue to avoid priority inversion
        audioQueue.async { [weak self] in
            guard let self = self else { return }
            
            let engine = AVAudioEngine()
            let node = AVAudioPlayerNode()
            let eq = AVAudioUnitEQ(numberOfBands: 10)
            
            // Configure each band
            for (index, frequency) in self.bandFrequencies.enumerated() {
                let band = eq.bands[index]
                band.frequency = frequency
                band.bandwidth = 1.0
                band.bypass = false
                band.gain = 0.0
            }
            
            engine.attach(node)
            engine.attach(eq)
            
            // Connect: playerNode -> EQ -> mixer (for analysis tap)
            engine.connect(node, to: eq, format: nil)
            engine.connect(eq, to: engine.mainMixerNode, format: nil)
            
            // Start engine so it's ready for analysis and playback
            do {
                try engine.start()
                print("EQ AudioEngine started successfully")
            } catch {
                print("Warning: Failed to start EQ engine: \(error)")
            }
            
            // Update properties on main thread after setup
            DispatchQueue.main.async {
                self.audioEngine = engine
                self.playerNode = node
                self.eqUnit = eq
                self.bands = eq.bands
            }
        }
    }
    
    func playFile(url: URL) throws {
        guard let engine = audioEngine, let node = playerNode else {
            throw NSError(domain: "Equalizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio engine not ready"])
        }
        
        // Load and schedule audio file
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        
        node.scheduleFile(file, at: nil) { [weak self] in
            // Playback finished
        }
        
        node.play()
    }
    
    func setBandGain(band: Int, gain: Float) throws {
        guard band >= 0 && band < 10 else {
            throw NSError(domain: "Equalizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Band index must be 0-9"])
        }
        guard gain >= -12.0 && gain <= 12.0 else {
            throw NSError(domain: "Equalizer", code: 2, userInfo: [NSLocalizedDescriptionKey: "Gain must be between -12.0 and +12.0 dB"])
        }
        
        // AVAudioUnitEQFilterParameters properties are thread-safe
        guard band < bands.count else { return }
        bands[band].gain = gain
    }
    
    func getBandGain(band: Int) throws -> Float {
        guard band >= 0 && band < 10 else {
            throw NSError(domain: "Equalizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Band index must be 0-9"])
        }
        guard band < bands.count else {
            throw NSError(domain: "Equalizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Band index out of range"])
        }
        return bands[band].gain
    }
    
    func reset() {
        // AVAudioUnitEQFilterParameters properties are thread-safe
        for band in bands {
            band.gain = 0.0
        }
    }
    
    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        // AVAudioUnitEQFilterParameters properties are thread-safe
        for band in bands {
            band.bypass = !enabled
        }
    }
    
    func isEnabled() -> Bool {
        return enabled
    }
    
    func getAudioEngine() -> AVAudioEngine? {
        return audioEngine
    }
    
    func getPlayerNode() -> AVAudioPlayerNode? {
        return playerNode
    }
}

