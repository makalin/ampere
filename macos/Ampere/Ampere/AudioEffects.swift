//
//  AudioEffects.swift
//  Ampere
//
//  Audio effects processing (Reverb, Delay, Chorus, etc.)
//

import Foundation
import AVFoundation
import Combine

class AudioEffects: ObservableObject {
    @Published var reverbEnabled: Bool = false
    @Published var reverbWetDryMix: Float = 0.0 // 0-100
    @Published var reverbPreset: AVAudioUnitReverbPreset = .mediumHall
    
    @Published var delayEnabled: Bool = false
    @Published var delayTime: Float = 0.25 // seconds
    @Published var delayFeedback: Float = 0.0 // -100 to 100
    @Published var delayWetDryMix: Float = 0.0 // 0-100
    
    @Published var chorusEnabled: Bool = false
    @Published var chorusDepth: Float = 0.0 // 0-100
    @Published var chorusRate: Float = 0.0 // 0.1-20 Hz
    @Published var chorusFeedback: Float = 0.0 // -100 to 100
    @Published var chorusWetDryMix: Float = 0.0 // 0-100
    
    @Published var distortionEnabled: Bool = false
    @Published var distortionPreset: AVAudioUnitDistortionPreset = .drumsBitBrush
    @Published var distortionWetDryMix: Float = 0.0 // 0-100
    @Published var distortionPreGain: Float = -6.0 // -6 to 6 dB
    
    private var audioEngine: AVAudioEngine?
    private var reverbUnit: AVAudioUnitReverb?
    private var delayUnit: AVAudioUnitDelay?
    private var chorusUnit: AVAudioUnitTimePitch?
    private var distortionUnit: AVAudioUnitDistortion?
    
    func setupEffects(audioEngine: AVAudioEngine) {
        self.audioEngine = audioEngine
        
        // Initialize effect units
        reverbUnit = AVAudioUnitReverb()
        delayUnit = AVAudioUnitDelay()
        chorusUnit = AVAudioUnitTimePitch()
        distortionUnit = AVAudioUnitDistortion()
        
        // Attach units
        if let reverb = reverbUnit {
            audioEngine.attach(reverb)
        }
        if let delay = delayUnit {
            audioEngine.attach(delay)
        }
        if let chorus = chorusUnit {
            audioEngine.attach(chorus)
        }
        if let distortion = distortionUnit {
            audioEngine.attach(distortion)
        }
    }
    
    func updateReverb() {
        guard let reverb = reverbUnit else { return }
        reverb.wetDryMix = reverbWetDryMix
        reverb.loadFactoryPreset(reverbPreset)
    }
    
    func updateDelay() {
        guard let delay = delayUnit else { return }
        delay.delayTime = TimeInterval(delayTime)
        delay.feedback = delayFeedback
        delay.wetDryMix = delayWetDryMix
        delay.lowPassCutoff = 15000.0
    }
    
    func updateChorus() {
        guard let chorus = chorusUnit else { return }
        // Chorus using time pitch with modulation
        chorus.rate = chorusRate
        chorus.pitch = 0.0 // No pitch shift
    }
    
    func updateDistortion() {
        guard let distortion = distortionUnit else { return }
        distortion.wetDryMix = distortionWetDryMix
        distortion.loadFactoryPreset(distortionPreset)
        distortion.preGain = distortionPreGain
    }
    
    func getReverbUnit() -> AVAudioUnitReverb? {
        return reverbUnit
    }
    
    func getDelayUnit() -> AVAudioUnitDelay? {
        return delayUnit
    }
    
    func getChorusUnit() -> AVAudioUnitTimePitch? {
        return chorusUnit
    }
    
    func getDistortionUnit() -> AVAudioUnitDistortion? {
        return distortionUnit
    }
}

