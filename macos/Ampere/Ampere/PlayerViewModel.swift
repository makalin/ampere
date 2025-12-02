//
//  PlayerViewModel.swift
//  Ampere
//
//  ViewModel for audio player using pure Swift
//

import SwiftUI
import Combine
import AVFoundation
import AVFAudio

class PlayerViewModel: ObservableObject {
    @Published var state: PlayerState = .stopped
    @Published var volume: Float = 1.0
    @Published var currentFile: String? = nil
    @Published var position: Double = 0.0
    @Published var duration: Double? = nil
    @Published var playlist: Playlist? = nil
    @Published var metadata: AudioMetadata = AudioMetadata()
    @Published var spectrumData: [Float] = Array(repeating: 0.0, count: 20)
    @Published var eqSpectrumData: [Float] = Array(repeating: 0.0, count: 10)
    
    private var player: AudioPlayer
    private var eq: Equalizer
    private var visualizer: AudioVisualizer
    private var eqAnalyzer: RealTimeEQAnalyzer?
    let channelSettings: ChannelSettings
    let dailySuggestions: DailySuggestions
    var pluginManager: PluginManager!
    let crossfadeManager: CrossfadeManager
    let replayGainProcessor: ReplayGainProcessor
    let listeningAnalytics: ListeningAnalytics
    
    var stateDescription: String {
        switch state {
        case .stopped:
            return "Stopped"
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        }
    }
    
    init() {
        // Initialize all basic properties first
        player = AudioPlayer()
        eq = Equalizer()
        let newPlaylist = Playlist()
        playlist = newPlaylist
        visualizer = AudioVisualizer()
        eqAnalyzer = RealTimeEQAnalyzer()
        channelSettings = ChannelSettings()
        crossfadeManager = CrossfadeManager()
        replayGainProcessor = ReplayGainProcessor()
        listeningAnalytics = ListeningAnalytics()
        
        // Initialize daily suggestions (doesn't need self)
        dailySuggestions = DailySuggestions(playlist: newPlaylist)
        
        // Now all stored properties except pluginManager are initialized
        // We can safely use self to create PluginContext
        let localPlayer = player
        let localEq = eq
        let pluginContext = PluginContext(
            player: localPlayer,
            playlist: newPlaylist,
            equalizer: localEq,
            viewModel: self
        )
        pluginManager = PluginManager(context: pluginContext)
        
        // Observe player state
        player.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$state)
        
        player.$volume
            .receive(on: DispatchQueue.main)
            .assign(to: &$volume)
        
        player.$currentFile
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentFile)
        
        player.$position
            .receive(on: DispatchQueue.main)
            .assign(to: &$position)
        
        player.$duration
            .receive(on: DispatchQueue.main)
            .assign(to: &$duration)
        
        // Observe spectrum data
        visualizer.$spectrumData
            .receive(on: DispatchQueue.main)
            .assign(to: &$spectrumData)
        
        // Observe EQ spectrum data
        eqAnalyzer?.$frequencyBands
            .receive(on: DispatchQueue.main)
            .assign(to: &$eqSpectrumData)
        
        // Start/stop visualization based on playback state
        $state
            .sink { [weak self] newState in
                guard let self = self else { return }
                self.visualizer.startVisualization(isPlaying: newState == .playing)
                
                // Start/stop EQ analyzer - always use animated visualization
                if newState == .playing {
                    // Use animated visualization for smooth display
                    self.eqAnalyzer?.startAnalysis(audioEngine: nil)
                } else {
                    self.eqAnalyzer?.stopAnalysis()
                }
            }
            .store(in: &cancellables)
        
        // Observe track end notification
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TrackDidFinish"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            // End analytics session
            self.listeningAnalytics.endSession()
            // Auto-play next track
            self.handleTrackEnd()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func loadFile(path: String) {
        do {
            // End previous analytics session
            if let currentPath = currentFile {
                listeningAnalytics.endSession()
            }
            
            try player.loadFile(path: path)
            // Extract metadata
            metadata = MetadataExtractor.extractMetadata(from: path)
            
            // Extract ReplayGain from metadata
            replayGainProcessor.extractReplayGain(from: metadata)
            
            // Apply ReplayGain volume adjustment
            let volumeAdjustment = replayGainProcessor.calculateVolumeAdjustment()
            if replayGainProcessor.mode != .off {
                let adjustedVolume = volume * volumeAdjustment
                try? player.setVolume(min(1.0, adjustedVolume))
            }
            
            // Start new analytics session
            listeningAnalytics.startSession(trackPath: path)
            listeningAnalytics.updateGenreAndArtist(trackPath: path, genre: metadata.genre, artist: metadata.artist)
            
            // Update playlist current index if file is in playlist
            if let playlist = playlist {
                for i in 0..<playlist.getLength() {
                    if let track = playlist.getTrack(at: i), track.path == path {
                        try? playlist.setCurrentTrackIndex(i)
                        break
                    }
                }
            }
        } catch {
            print("Failed to load file: \(error)")
        }
    }
    
    func loadFile(url: URL) {
        do {
            // End previous analytics session
            if let currentPath = currentFile {
                listeningAnalytics.endSession()
            }
            
            try player.loadFile(url: url)
            
            // Extract metadata
            metadata = MetadataExtractor.extractMetadata(from: url.path)
            
            // Extract ReplayGain from metadata
            replayGainProcessor.extractReplayGain(from: metadata)
            
            // Apply ReplayGain volume adjustment
            let volumeAdjustment = replayGainProcessor.calculateVolumeAdjustment()
            if replayGainProcessor.mode != .off {
                let adjustedVolume = volume * volumeAdjustment
                try? player.setVolume(min(1.0, adjustedVolume))
            }
            
            // Start new analytics session
            listeningAnalytics.startSession(trackPath: url.path)
            listeningAnalytics.updateGenreAndArtist(trackPath: url.path, genre: metadata.genre, artist: metadata.artist)
            
            // Update playlist current index if file is in playlist
            if let playlist = playlist {
                for i in 0..<playlist.getLength() {
                    if let track = playlist.getTrack(at: i), track.path == url.path {
                        try? playlist.setCurrentTrackIndex(i)
                        break
                    }
                }
            }
        } catch {
            print("Failed to load file: \(error)")
        }
    }
    
    func play() {
        do {
            // Play ONLY on AVPlayer (single audio output)
            try player.play()
            print("Play called - state should be playing")
        } catch {
            print("Failed to play: \(error)")
            // Try again after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                do {
                    try self.player.play()
                } catch {
                    print("Retry play failed: \(error)")
                }
            }
        }
    }
    
    func pause() {
        do {
            try player.pause()
        } catch {
            print("Failed to pause: \(error)")
        }
    }
    
    func stop() {
        do {
            try player.stop()
        } catch {
            print("Failed to stop: \(error)")
        }
    }
    
    func setVolume(_ newVolume: Float) {
        do {
            try player.setVolume(newVolume)
        } catch {
            print("Failed to set volume: \(error)")
        }
    }
    
    // EQ Methods
    func setEQBand(index: Int, gain: Float) {
        do {
            try eq.setBandGain(band: index, gain: gain)
        } catch {
            print("Failed to set EQ band: \(error)")
        }
    }
    
    func getEQBand(index: Int) -> Float? {
        do {
            return try eq.getBandGain(band: index)
        } catch {
            return nil
        }
    }
    
    func resetEQ() {
        eq.reset()
    }
    
    func setEQEnabled(_ enabled: Bool) {
        eq.setEnabled(enabled)
    }
    
    func isEQEnabled() -> Bool {
        return eq.isEnabled()
    }
    
    // Playlist Methods
    func createPlaylist() {
        playlist = Playlist()
    }
    
    func addToPlaylist(path: String) {
        guard let playlist = playlist else {
            createPlaylist()
            addToPlaylist(path: path)
            return
        }
        do {
            try playlist.addFile(path: path)
        } catch {
            print("Failed to add to playlist: \(error)")
        }
    }
    
    func playNext() {
        guard let playlist = playlist, !playlist.isEmpty() else {
            return
        }
        
        if let nextTrack = playlist.getNextTrack() {
            // If crossfade is enabled, fade out current track first
            if crossfadeManager.enabled && crossfadeManager.duration > 0, 
               let currentPlayer = player.getAVPlayer(), state == .playing {
                crossfadeManager.startFadeOut(player: currentPlayer) { [weak self] in
                    guard let self = self else { return }
                    self.loadFile(path: nextTrack.path)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                        guard let self = self, let nextPlayer = self.player.getAVPlayer() else { return }
                        // Fade in next track
                        self.crossfadeManager.startFadeIn(player: nextPlayer) {
                            // Fade in complete
                        }
                        self.play()
                    }
                }
            } else {
                loadFile(path: nextTrack.path)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.play()
                }
            }
        }
    }
    
    func playPrevious() {
        guard let playlist = playlist, !playlist.isEmpty() else {
            return
        }
        
        if let prevTrack = playlist.getPreviousTrack() {
            loadFile(path: prevTrack.path)
            // Small delay to ensure file is loaded before playing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.play()
            }
        }
    }
    
    func seek(to position: Double) {
        player.seek(to: position)
    }
    
    private func handleTrackEnd() {
        guard let playlist = playlist else { return }
        let repeatMode = playlist.getRepeatMode()
        
        if repeatMode == .one {
            // Song loop - replay current track
            if let currentPath = currentFile {
                loadFile(path: currentPath)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.play()
                }
            }
        } else {
            // Play next track (or loop playlist if repeatMode == .all)
            playNext()
        }
    }
}
