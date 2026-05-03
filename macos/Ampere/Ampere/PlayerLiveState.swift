//
//  PlayerLiveState.swift
//  Ampere
//
//  High-frequency playback / visualization data kept separate from PlayerViewModel
//  so static UI (playlist, settings, etc.) is not re-rendered every frame.
//

import Combine

final class PlayerLiveState: ObservableObject {
    @Published var spectrumData: [Float] = Array(repeating: 0.0, count: 20)
    @Published var eqSpectrumData: [Float] = Array(repeating: 0.0, count: 10)
    @Published var position: Double = 0.0
    @Published var duration: Double? = nil
}
