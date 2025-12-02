//
//  CrossfadeManager.swift
//  Ampere
//
//  Manages crossfade transitions between tracks
//

import Foundation
import AVFoundation
import Combine

class CrossfadeManager: ObservableObject {
    @Published var enabled: Bool = false
    @Published var duration: Double = 3.0 // Default 3 seconds
    
    private var fadeTimer: Timer?
    private var fadeStartTime: Date?
    private var fadeStartVolume: Float = 1.0
    private var fadeTargetVolume: Float = 0.0
    private var isFadingOut: Bool = false
    private var isFadingIn: Bool = false
    
    // Callbacks
    var onFadeOutComplete: (() -> Void)?
    var onFadeInComplete: (() -> Void)?
    
    private weak var currentPlayer: AVPlayer?
    private weak var nextPlayer: AVPlayer?
    
    init() {
        // Load settings from UserDefaults
        if let savedEnabled = UserDefaults.standard.object(forKey: "CrossfadeEnabled") as? Bool {
            enabled = savedEnabled
        }
        if let savedDuration = UserDefaults.standard.object(forKey: "CrossfadeDuration") as? Double {
            duration = savedDuration
        }
    }
    
    func setEnabled(_ value: Bool) {
        enabled = value
        UserDefaults.standard.set(value, forKey: "CrossfadeEnabled")
    }
    
    func setDuration(_ value: Double) {
        duration = max(0.0, min(10.0, value)) // Clamp between 0-10 seconds
        UserDefaults.standard.set(duration, forKey: "CrossfadeDuration")
    }
    
    func startFadeOut(player: AVPlayer, completion: @escaping () -> Void) {
        guard enabled && duration > 0 else {
            completion()
            return
        }
        
        isFadingOut = true
        currentPlayer = player
        fadeStartTime = Date()
        fadeStartVolume = player.volume
        fadeTargetVolume = 0.0
        onFadeOutComplete = completion
        
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateFadeOut()
        }
    }
    
    func startFadeIn(player: AVPlayer, completion: (() -> Void)? = nil) {
        guard enabled && duration > 0 else {
            completion?()
            return
        }
        
        isFadingIn = true
        nextPlayer = player
        let targetVolume = player.volume
        player.volume = 0.0
        fadeStartTime = Date()
        fadeStartVolume = 0.0
        fadeTargetVolume = targetVolume
        onFadeInComplete = completion
        
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateFadeIn()
        }
    }
    
    private func updateFadeOut() {
        guard let player = currentPlayer,
              let startTime = fadeStartTime,
              isFadingOut else {
            fadeTimer?.invalidate()
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / duration, 1.0)
        
        // Use smooth fade curve (ease-out)
        let easedProgress = 1.0 - pow(1.0 - progress, 3.0)
        let currentVolume = fadeStartVolume * (1.0 - Float(easedProgress))
        
        player.volume = max(0.0, currentVolume)
        
        if progress >= 1.0 {
            player.volume = 0.0
            isFadingOut = false
            fadeTimer?.invalidate()
            fadeTimer = nil
            onFadeOutComplete?()
            onFadeOutComplete = nil
        }
    }
    
    private func updateFadeIn() {
        guard let player = nextPlayer,
              let startTime = fadeStartTime,
              isFadingIn else {
            fadeTimer?.invalidate()
            return
        }
        
        let elapsed = Date().timeIntervalSince(startTime)
        let progress = min(elapsed / duration, 1.0)
        
        // Use smooth fade curve (ease-in)
        let easedProgress = pow(progress, 2.0)
        let currentVolume = fadeStartVolume + Float(easedProgress) * (fadeTargetVolume - fadeStartVolume)
        
        player.volume = min(fadeTargetVolume, currentVolume)
        
        if progress >= 1.0 {
            player.volume = fadeTargetVolume
            isFadingIn = false
            fadeTimer?.invalidate()
            fadeTimer = nil
            onFadeInComplete?()
            onFadeInComplete = nil
        }
    }
    
    func cancelFade() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        isFadingOut = false
        isFadingIn = false
        onFadeOutComplete = nil
        onFadeInComplete = nil
    }
    
    deinit {
        cancelFade()
    }
}

