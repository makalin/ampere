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
    /// Finishes starting playback when `AVPlayerItem` becomes `.readyToPlay` after `loadFile`.
    private var pendingPlayObserver: NSKeyValueObservation?
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
        pendingPlayObserver?.invalidate()
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
        pendingPlayObserver?.invalidate()
        pendingPlayObserver = nil
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
        
        syncDurationFromItem()
        
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
                    syncDurationFromItem()
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
        guard let player = player, let item = playerItem else {
            print("ERROR: Cannot play - no player or playerItem")
            throw NSError(domain: "AudioPlayer", code: 2, userInfo: [NSLocalizedDescriptionKey: "No file loaded"])
        }
        player.volume = volume
        pendingPlayObserver?.invalidate()
        pendingPlayObserver = nil
        
        let kickPlayback = { [weak self] in
            guard let self = self, let p = self.player else { return }
            p.volume = self.volume
            p.play()
            DispatchQueue.main.async {
                self.state = .playing
                self.syncDurationFromItem()
            }
        }
        
        switch item.status {
        case .readyToPlay:
            kickPlayback()
        case .failed:
            let err = item.error?.localizedDescription ?? "Playback failed"
            print("PlayerItem failed: \(err)")
            throw item.error ?? NSError(domain: "AudioPlayer", code: 4, userInfo: [NSLocalizedDescriptionKey: err])
        default:
            pendingPlayObserver = item.observe(\.status, options: [.new]) { [weak self] observed, _ in
                guard let self = self else { return }
                switch observed.status {
                case .readyToPlay:
                    self.pendingPlayObserver?.invalidate()
                    self.pendingPlayObserver = nil
                    kickPlayback()
                case .failed:
                    self.pendingPlayObserver?.invalidate()
                    self.pendingPlayObserver = nil
                    DispatchQueue.main.async { self.state = .stopped }
                    print("PlayerItem failed while preparing")
                default:
                    break
                }
            }
            player.play()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self, let p = self.player, let it = self.playerItem else { return }
            if p.rate == 0, it.status == .readyToPlay {
                p.volume = self.volume
                p.play()
            }
            self.syncDurationFromItem()
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
    
    /// Resolves duration from the item (KVO often leaves `duration` nil until the asset finishes loading).
    private func syncDurationFromItem() {
        guard let item = playerItem else { return }
        let seconds = CMTimeGetSeconds(item.duration)
        if !seconds.isNaN && seconds.isFinite && seconds > 0 {
            DispatchQueue.main.async { [weak self] in
                self?.duration = seconds
            }
            return
        }
        let asset = item.asset
        Task { [weak self] in
            guard let self else { return }
            do {
                let cm = try await asset.load(.duration)
                let s = CMTimeGetSeconds(cm)
                guard !s.isNaN && s.isFinite && s > 0 else { return }
                await MainActor.run {
                    guard self.playerItem?.asset === asset else { return }
                    self.duration = s
                }
            } catch {
                print("async duration load failed: \(error)")
            }
        }
    }
    
    func seek(to position: Double) {
        guard let player = player, let item = playerItem else { return }
        var dur = duration ?? 0
        if dur <= 0 {
            let s = CMTimeGetSeconds(item.duration)
            if !s.isNaN && s.isFinite && s > 0 {
                dur = s
                DispatchQueue.main.async { [weak self] in self?.duration = s }
            } else {
                syncDurationFromItem()
                return
            }
        }
        
        let clampedPosition = max(0.0, min(position, dur))
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
        stopPositionTimer()
        let t = Timer(timeInterval: positionUpdateInterval, repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
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
