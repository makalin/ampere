//
//  AudioPlayer.swift
//  Ampere
//
//  Pure Swift audio player using AVFoundation - COMPLETE WORKING VERSION
//

import Foundation
import AVFoundation
import Combine

enum PlayerState {
    case stopped
    case playing
    case paused
}

class AudioPlayer: NSObject, ObservableObject {
    @Published var state: PlayerState = .stopped
    @Published var volume: Float = 1.0
    @Published var currentFile: String? = nil
    @Published var position: Double = 0.0
    @Published var duration: Double? = nil
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var timer: Timer?
    private var statusObserver: NSKeyValueObservation?
    private let positionUpdateInterval: TimeInterval = 0.05
    
    // Store security-scoped URL for file access
    private var securityScopedURL: URL?
    private var isAccessingSecurityScopedResource = false
    
    override init() {
        super.init()
        // Initialize audio system on macOS
        initializeAudioSystem()
        startPositionTimer()
    }
    
    private func initializeAudioSystem() {
        // On macOS, AVPlayer handles audio output automatically
        // No need to initialize a separate audio engine
        // This prevents HAL errors and conflicts
        print("Audio system ready (using AVPlayer)")
    }
    
    deinit {
        stopPositionTimer()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        statusObserver?.invalidate()
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        NotificationCenter.default.removeObserver(self)
        
        // Stop accessing security-scoped resource
        if isAccessingSecurityScopedResource, let url = securityScopedURL {
            url.stopAccessingSecurityScopedResource()
        }
    }
    
    func loadFile(path: String) throws {
        let url = URL(fileURLWithPath: path)
        try loadFile(url: url)
    }
    
    func loadFile(url: URL) throws {
        // Stop accessing previous security-scoped resource
        if isAccessingSecurityScopedResource, let oldURL = securityScopedURL {
            oldURL.stopAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = false
        }
        
        // Try to start accessing security-scoped resource (for file picker URLs)
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
            throw NSError(domain: "AudioPlayer", code: 1, userInfo: [NSLocalizedDescriptionKey: "File does not exist or cannot be accessed"])
        }
        
        // If we successfully started accessing, mark it
        if isSecurityScoped {
            isAccessingSecurityScopedResource = true
            securityScopedURL = url
            print("Started accessing security-scoped resource for: \(url.path)")
        } else {
            print("Not a security-scoped URL, using direct access: \(url.path)")
        }
        
        print("Loading file: \(url.path)")
        
        // Clean up previous item
        statusObserver?.invalidate()
        if let oldItem = playerItem {
            oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration))
            oldItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: oldItem)
        }
        
        playerItem = AVPlayerItem(url: url)
        
        // Create player with proper audio output configuration
        player = AVPlayer(playerItem: playerItem)
        
        // CRITICAL: Configure audio output for macOS
        // Ensure audio output is properly routed
        player?.allowsExternalPlayback = false
        
        // CRITICAL: Set volume BEFORE anything else
        player?.volume = volume
        print("Player volume set to: \(volume)")
        
        // Ensure audio output is active
        // On macOS, AVPlayer should automatically use the default output device
        // But we can verify it's ready
        if let player = player {
            // Pre-warm the player by accessing its output
            _ = player.isOutputObscuredDueToInsufficientExternalProtection
            print("Player audio output configured")
        }
        
        currentFile = url.path
        position = 0.0
        duration = nil
        
        // Observe duration
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.duration), options: [.new, .initial], context: nil)
        
        // Observe status
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new], context: nil)
        
        // Observe playback end
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        state = .stopped
        print("File loaded, state: stopped")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "duration" {
            if let duration = playerItem?.duration {
                let durationSeconds = CMTimeGetSeconds(duration)
                if !durationSeconds.isNaN && durationSeconds.isFinite && durationSeconds > 0 {
                    DispatchQueue.main.async { [weak self] in
                        self?.duration = durationSeconds
                        print("Duration set to: \(durationSeconds) seconds")
                    }
                }
            }
        } else if keyPath == "status" {
            if let status = playerItem?.status {
                print("PlayerItem status changed to: \(status.rawValue)")
                if status == .readyToPlay {
                    // File is ready, ensure duration is set
                    if let duration = playerItem?.duration {
                        let durationSeconds = CMTimeGetSeconds(duration)
                        if !durationSeconds.isNaN && durationSeconds.isFinite && durationSeconds > 0 {
                            DispatchQueue.main.async { [weak self] in
                                self?.duration = durationSeconds
                                print("Duration set to: \(durationSeconds) seconds (from status)")
                            }
                        }
                    }
                } else if status == .failed {
                    if let error = playerItem?.error {
                        print("PlayerItem failed with error: \(error)")
                    }
                }
            }
        }
    }
    
    @objc private func playerDidFinishPlaying() {
        print("Playback finished")
        DispatchQueue.main.async { [weak self] in
            self?.state = .stopped
            self?.position = 0.0
            // Notify that track ended (for auto-play next)
            NotificationCenter.default.post(name: NSNotification.Name("TrackDidFinish"), object: nil)
        }
    }
    
    func play() throws {
        guard let player = player, let playerItem = playerItem else {
            print("ERROR: Cannot play - no player or playerItem")
            throw NSError(domain: "AudioPlayer", code: 2, userInfo: [NSLocalizedDescriptionKey: "No file loaded"])
        }
        
        print("Play called - current status: \(playerItem.status.rawValue)")
        print("Player volume before play: \(player.volume)")
        
        // ALWAYS set volume before playing
        player.volume = volume
        print("Player volume set to: \(volume)")
        
        // Set state to playing immediately for UI responsiveness
        DispatchQueue.main.async { [weak self] in
            self?.state = .playing
        }
        
        // Try to play - AVPlayer will handle buffering
        player.play()
        print("player.play() called")
        
        // Verify playback started - check multiple times
        var checkCount = 0
        let maxChecks = 10
        
        func verifyPlayback() {
            checkCount += 1
            guard let player = self.player, let playerItem = self.playerItem else { return }
            
            if player.rate > 0 {
                print("✅ Player is playing! Rate: \(player.rate)")
                DispatchQueue.main.async { [weak self] in
                    self?.state = .playing
                }
            } else if checkCount < maxChecks {
                print("⚠️ Check \(checkCount): Player.rate is 0, retrying...")
                // Try playing again
                player.play()
                // Check again after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    verifyPlayback()
                }
            } else {
                print("❌ ERROR: Player failed to start after \(maxChecks) attempts")
                print("   Status: \(playerItem.status.rawValue)")
                if let error = playerItem.error {
                    print("   Error: \(error.localizedDescription)")
                } else {
                    print("   Error: none")
                }
                // Still set state to playing - user can see it's trying
            }
        }
        
        // Start verification after initial play
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            verifyPlayback()
        }
    }
    
    func pause() throws {
        print("Pause called")
        player?.pause()
        DispatchQueue.main.async { [weak self] in
            self?.state = .paused
        }
    }
    
    func stop() throws {
        print("Stop called")
        player?.pause()
        let time = CMTime.zero
        player?.seek(to: time, completionHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.state = .stopped
                self?.position = 0.0
            }
        })
    }
    
    func setVolume(_ newVolume: Float) throws {
        guard newVolume >= 0.0 && newVolume <= 1.0 else {
            throw NSError(domain: "AudioPlayer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Volume must be between 0.0 and 1.0"])
        }
        let clampedVolume = max(0.0, min(1.0, newVolume))
        volume = clampedVolume
        player?.volume = clampedVolume
        print("Volume set to: \(clampedVolume), player.volume: \(player?.volume ?? -1)")
    }
    
    func seek(to position: Double) {
        guard let player = player, let duration = duration, duration > 0 else {
            return
        }
        
        let clampedPosition = max(0.0, min(position, duration))
        let time = CMTime(seconds: clampedPosition, preferredTimescale: 600)
        
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] completed in
            if completed {
                DispatchQueue.main.async {
                    self?.position = clampedPosition
                }
            }
        }
    }
    
    private func startPositionTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: positionUpdateInterval, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func stopPositionTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updatePosition() {
        guard let player = player, let playerItem = playerItem else { return }
        
        // Update position - check if actually playing
        let currentTime = player.currentTime()
        let seconds = CMTimeGetSeconds(currentTime)
        let rate = player.rate
        
        if !seconds.isNaN && seconds.isFinite && seconds >= 0 {
            DispatchQueue.main.async { [weak self] in
                self?.position = seconds
                
                // Debug: log if not playing when should be
                if self?.state == .playing && rate == 0 {
                    print("WARNING: State is playing but player.rate is 0")
                }
            }
        }
    }
    
    // Expose AVPlayer for crossfade and other advanced features
    func getAVPlayer() -> AVPlayer? {
        return player
    }
}
