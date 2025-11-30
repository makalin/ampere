//
//  PlaylistPersistence.swift
//  Ampere
//
//  Save and restore playlist state
//

import Foundation

class PlaylistPersistence {
    private static let playlistKey = "com.ampere.playlist"
    private static let currentIndexKey = "com.ampere.currentIndex"
    private static let repeatModeKey = "com.ampere.repeatMode"
    private static let shuffleModeKey = "com.ampere.shuffleMode"
    
    static func savePlaylist(_ playlist: Playlist) {
        let userDefaults = UserDefaults.standard
        
        // Save all tracks
        var tracks: [[String: Any]] = []
        for i in 0..<playlist.getLength() {
            if let track = playlist.getTrack(at: i) {
                var trackDict: [String: Any] = ["path": track.path]
                if let title = track.title { trackDict["title"] = title }
                if let artist = track.artist { trackDict["artist"] = artist }
                if let album = track.album { trackDict["album"] = album }
                if let duration = track.duration { trackDict["duration"] = duration }
                if let genre = track.genre { trackDict["genre"] = genre }
                if let year = track.year { trackDict["year"] = year }
                tracks.append(trackDict)
            }
        }
        userDefaults.set(tracks, forKey: playlistKey)
        
        // Save current index
        if let currentIndex = playlist.getCurrentTrackIndex() {
            userDefaults.set(currentIndex, forKey: currentIndexKey)
        } else {
            userDefaults.removeObject(forKey: currentIndexKey)
        }
        
        // Save repeat mode
        let repeatMode = playlist.getRepeatMode()
        userDefaults.set(repeatMode == .all ? "all" : (repeatMode == .one ? "one" : "none"), forKey: repeatModeKey)
        
        // Save shuffle mode
        let shuffleMode = playlist.getShuffleMode()
        userDefaults.set(shuffleMode == .on ? "on" : "off", forKey: shuffleModeKey)
        
        userDefaults.synchronize()
    }
    
    static func loadPlaylist() -> (tracks: [PlaylistEntry], currentIndex: Int?, repeatMode: RepeatMode, shuffleMode: ShuffleMode) {
        let userDefaults = UserDefaults.standard
        
        // Load tracks
        var tracks: [PlaylistEntry] = []
        if let tracksData = userDefaults.array(forKey: playlistKey) as? [[String: Any]] {
            for trackDict in tracksData {
                if let path = trackDict["path"] as? String, FileManager.default.fileExists(atPath: path) {
                    let entry = PlaylistEntry(
                        path: path,
                        title: trackDict["title"] as? String,
                        artist: trackDict["artist"] as? String,
                        album: trackDict["album"] as? String,
                        duration: trackDict["duration"] as? Double,
                        genre: trackDict["genre"] as? String,
                        year: trackDict["year"] as? Int
                    )
                    tracks.append(entry)
                }
            }
        }
        
        // Load current index
        let currentIndex = userDefaults.object(forKey: currentIndexKey) as? Int
        let validIndex = currentIndex != nil && currentIndex! >= 0 && currentIndex! < tracks.count ? currentIndex : nil
        
        // Load repeat mode
        let repeatModeString = userDefaults.string(forKey: repeatModeKey) ?? "none"
        let repeatMode: RepeatMode = repeatModeString == "all" ? .all : (repeatModeString == "one" ? .one : .none)
        
        // Load shuffle mode
        let shuffleModeString = userDefaults.string(forKey: shuffleModeKey) ?? "off"
        let shuffleMode: ShuffleMode = shuffleModeString == "on" ? .on : .off
        
        return (tracks, validIndex, repeatMode, shuffleMode)
    }
}

