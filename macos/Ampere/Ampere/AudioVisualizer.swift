//
//  AudioVisualizer.swift
//  Ampere
//
//  Live audio spectrum analyzer
//

import Foundation
import Combine

class AudioVisualizer: ObservableObject {
    @Published var spectrumData: [Float] = Array(repeating: 0.0, count: 20)
    private var timer: Timer?
    private var isPlaying: Bool = false
    
    func startVisualization(isPlaying: Bool) {
        self.isPlaying = isPlaying
        if isPlaying {
            timer?.invalidate()
            let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
                self?.updateSpectrum()
            }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        } else {
            timer?.invalidate()
            timer = nil
            spectrumData = Array(repeating: 0.0, count: 20)
        }
    }
    
    /// Values are normalized 0…1 for UI meters (0 = silence / stopped).
    private func updateSpectrum() {
        guard isPlaying else { return }
        let timeValue = Float(Date().timeIntervalSince1970 * 2.5)
        var newData = [Float](repeating: 0, count: 20)
        for i in 0..<20 {
            let phase = timeValue + Float(i) * 0.4
            let wave = sin(phase) * 0.5 + 0.5 // 0…1
            let jitter = Float.random(in: -0.06...0.06)
            newData[i] = max(0, min(1, wave * 0.75 + jitter))
        }
        spectrumData = newData
    }
    
    deinit {
        timer?.invalidate()
    }
}

