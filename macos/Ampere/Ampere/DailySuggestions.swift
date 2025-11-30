//
//  DailySuggestions.swift
//  Ampere
//
//  Daily music suggestions based on listening history
//

import Foundation
import Combine

struct SuggestedTrack: Identifiable {
    let id: String
    let title: String
    let artist: String
    let path: String
    let reason: String // Why it was suggested
    let playCount: Int
    let lastPlayed: Date?
}

class DailySuggestions: ObservableObject {
    @Published var suggestions: [SuggestedTrack] = []
    @Published var dailyPlaylist: [SuggestedTrack] = []
    
    private let maxSuggestions = 20
    private let playlist: Playlist?
    
    init(playlist: Playlist?) {
        self.playlist = playlist
        generateDailySuggestions()
    }
    
    func generateDailySuggestions() {
        guard let playlist = playlist else { return }
        
        var tracks: [SuggestedTrack] = []
        let today = Calendar.current.startOfDay(for: Date())
        
        // Analyze listening patterns
        for i in 0..<playlist.getLength() {
            guard let track = playlist.getTrack(at: i) else { continue }
            
            // Get play history (would be stored in UserDefaults or database)
            let playCount = UserDefaults.standard.integer(forKey: "playCount_\(track.path)")
            let lastPlayedKey = "lastPlayed_\(track.path)"
            let lastPlayed = UserDefaults.standard.object(forKey: lastPlayedKey) as? Date
            
            // Calculate score based on:
            // - Play frequency
            // - Recency
            // - Time of day patterns
            var score = Double(playCount)
            
            if let lastPlayed = lastPlayed {
                let daysSince = Calendar.current.dateComponents([.day], from: lastPlayed, to: today).day ?? 0
                // Boost recently played tracks
                score += Double(max(0, 7 - daysSince)) * 0.5
            } else {
                // Boost never-played tracks for discovery
                score += 2.0
            }
            
            // Time-based suggestions (favor tracks played at similar times)
            let hour = Calendar.current.component(.hour, from: Date())
            if let lastPlayed = lastPlayed {
                let lastHour = Calendar.current.component(.hour, from: lastPlayed)
                if abs(hour - lastHour) < 3 {
                    score += 1.0
                }
            }
            
            let reason: String
            if playCount == 0 {
                reason = "New discovery"
            } else if playCount > 10 {
                reason = "Your favorite"
            } else if let lastPlayed = lastPlayed, Calendar.current.dateComponents([.day], from: lastPlayed, to: today).day ?? 0 < 3 {
                reason = "Recently played"
            } else {
                reason = "Based on your taste"
            }
            
            tracks.append(SuggestedTrack(
                id: track.path,
                title: track.title ?? URL(fileURLWithPath: track.path).deletingPathExtension().lastPathComponent,
                artist: track.artist ?? "",
                path: track.path,
                reason: reason,
                playCount: playCount,
                lastPlayed: lastPlayed
            ))
        }
        
        // Sort by score and take top suggestions
        suggestions = tracks.sorted { $0.playCount > $1.playCount }.prefix(maxSuggestions).map { $0 }
        
        // Generate daily playlist (mix of favorites and discoveries)
        generateDailyPlaylist()
    }
    
    private func generateDailyPlaylist() {
        let favorites = suggestions.filter { $0.playCount > 5 }.prefix(10)
        let discoveries = suggestions.filter { $0.playCount == 0 }.prefix(10)
        
        dailyPlaylist = Array(favorites + discoveries).shuffled()
    }
    
    func recordPlay(trackPath: String) {
        let key = "playCount_\(trackPath)"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
        UserDefaults.standard.set(Date(), forKey: "lastPlayed_\(trackPath)")
        
        // Regenerate suggestions
        generateDailySuggestions()
    }
    
    func exportDailyPlaylist() -> String {
        // Export as M3U playlist
        var m3u = "#EXTM3U\n"
        for track in dailyPlaylist {
            m3u += "#EXTINF:-1,\(track.artist) - \(track.title)\n"
            m3u += "\(track.path)\n"
        }
        return m3u
    }
    
    func saveDailyPlaylist(to url: URL) throws {
        let m3u = exportDailyPlaylist()
        try m3u.write(to: url, atomically: true, encoding: .utf8)
    }
}

