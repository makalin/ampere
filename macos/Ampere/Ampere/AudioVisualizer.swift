//
//  AudioVisualizer.swift
//  Ampere
//
//  Live audio spectrum analyzer
//

import Foundation
import AVFoundation
import Combine

class AudioVisualizer: ObservableObject {
    @Published var spectrumData: [Float] = Array(repeating: 0.0, count: 20)
    private var timer: Timer?
    private var isPlaying: Bool = false
    
    func startVisualization(isPlaying: Bool) {
        self.isPlaying = isPlaying
        if isPlaying {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateSpectrum()
            }
        } else {
            timer?.invalidate()
            spectrumData = Array(repeating: 0.0, count: 20)
        }
    }
    
    private func updateSpectrum() {
        // Generate animated spectrum data (mock for now - can be replaced with real FFT later)
        var newData: [Float] = []
        let timeValue = Date().timeIntervalSince1970 * 2.0
        
        for i in 0..<20 {
            let base = Float.random(in: 5...15)
            let indexFloat = Float(i)
            let sinInput = indexFloat * 0.5 + Float(timeValue)
            let sinValue = sin(sinInput)
            let variation = sinValue * 5.0
            let value = base + variation
            let clampedValue = max(2.0, min(20.0, value))
            newData.append(clampedValue)
        }
        spectrumData = newData
    }
    
    deinit {
        timer?.invalidate()
    }
}

