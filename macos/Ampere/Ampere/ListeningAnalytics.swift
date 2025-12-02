//
//  ListeningAnalytics.swift
//  Ampere
//
//  Advanced analytics for listening statistics
//

import Foundation
import Combine

struct ListeningSession {
    let trackPath: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        guard let end = endTime else {
            return Date().timeIntervalSince(startTime)
        }
        return end.timeIntervalSince(startTime)
    }
    var completed: Bool {
        guard let end = endTime else { return false }
        return duration > 30.0 // Consider completed if played for more than 30 seconds
    }
}

struct TrackStatistics {
    let path: String
    var playCount: Int = 0
    var totalPlayTime: TimeInterval = 0.0
    var lastPlayed: Date?
    var firstPlayed: Date?
    var averagePlayTime: TimeInterval {
        guard playCount > 0 else { return 0.0 }
        return totalPlayTime / Double(playCount)
    }
    var completionRate: Double {
        guard playCount > 0 else { return 0.0 }
        // Estimate completion rate based on average play time vs typical track length
        // This is a simplified calculation
        return min(1.0, averagePlayTime / 180.0) // Assume 3 min average track
    }
}

struct ListeningStats {
    var totalTracksPlayed: Int = 0
    var totalListeningTime: TimeInterval = 0.0
    var uniqueTracksPlayed: Int = 0
    var favoriteGenres: [String: Int] = [:]
    var favoriteArtists: [String: Int] = [:]
    var listeningByHour: [Int: Int] = [:] // Hour of day -> play count
    var listeningByDay: [String: Int] = [:] // Day of week -> play count
    var topTracks: [TrackStatistics] = []
    var recentTracks: [String] = []
    
    var averageSessionLength: TimeInterval {
        guard totalTracksPlayed > 0 else { return 0.0 }
        return totalListeningTime / Double(totalTracksPlayed)
    }
    
    var totalListeningHours: Double {
        return totalListeningTime / 3600.0
    }
}

class ListeningAnalytics: ObservableObject {
    @Published var stats: ListeningStats = ListeningStats()
    @Published var trackStats: [String: TrackStatistics] = [:]
    
    private var currentSession: ListeningSession?
    private let persistenceKey = "ListeningAnalytics"
    private let trackStatsKey = "TrackStatistics"
    
    init() {
        loadStats()
    }
    
    func startSession(trackPath: String) {
        // End previous session if exists
        if let session = currentSession {
            endSession()
        }
        
        currentSession = ListeningSession(trackPath: trackPath, startTime: Date())
        
        // Update track statistics
        updateTrackStats(path: trackPath, isStart: true)
    }
    
    func endSession() {
        guard var session = currentSession else { return }
        session.endTime = Date()
        
        // Update statistics
        if session.completed {
            stats.totalTracksPlayed += 1
            stats.totalListeningTime += session.duration
            
            updateTrackStats(path: session.trackPath, duration: session.duration, isStart: false)
            updateGenreAndArtistStats(trackPath: session.trackPath)
            updateTimeBasedStats()
        }
        
        currentSession = nil
        saveStats()
    }
    
    private func updateTrackStats(path: String, duration: TimeInterval? = nil, isStart: Bool) {
        if trackStats[path] == nil {
            trackStats[path] = TrackStatistics(path: path)
            stats.uniqueTracksPlayed += 1
        }
        
        var trackStat = trackStats[path]!
        
        if isStart {
            trackStat.playCount += 1
            trackStat.lastPlayed = Date()
            if trackStat.firstPlayed == nil {
                trackStat.firstPlayed = Date()
            }
        }
        
        if let duration = duration {
            trackStat.totalPlayTime += duration
        }
        
        trackStats[path] = trackStat
        
        // Update top tracks
        updateTopTracks()
    }
    
    private func updateGenreAndArtistStats(trackPath: String) {
        // Extract metadata to get genre and artist
        // This would ideally use the metadata from PlayerViewModel
        // For now, we'll store the path and extract later if needed
    }
    
    func updateGenreAndArtist(trackPath: String, genre: String?, artist: String?) {
        if let genre = genre, !genre.isEmpty {
            stats.favoriteGenres[genre, default: 0] += 1
        }
        if let artist = artist, !artist.isEmpty {
            stats.favoriteArtists[artist, default: 0] += 1
        }
    }
    
    private func updateTimeBasedStats() {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let dayName = calendar.weekdaySymbols[weekday - 1]
        
        stats.listeningByHour[hour, default: 0] += 1
        stats.listeningByDay[dayName, default: 0] += 1
    }
    
    private func updateTopTracks() {
        let sorted = trackStats.values.sorted { $0.playCount > $1.playCount }
        stats.topTracks = Array(sorted.prefix(20)) // Top 20 tracks
    }
    
    func getTopTracks(limit: Int = 10) -> [TrackStatistics] {
        return Array(stats.topTracks.prefix(limit))
    }
    
    func getTopGenres(limit: Int = 5) -> [(String, Int)] {
        return stats.favoriteGenres.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }
    
    func getTopArtists(limit: Int = 5) -> [(String, Int)] {
        return stats.favoriteArtists.sorted { $0.value > $1.value }.prefix(limit).map { ($0.key, $0.value) }
    }
    
    func getListeningPeakHours() -> [Int] {
        return stats.listeningByHour.sorted { $0.value > $1.value }.prefix(3).map { $0.key }
    }
    
    private func saveStats() {
        // Save to UserDefaults (for simple persistence)
        // In a production app, you might use CoreData or a database
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
        
        // Save track stats
        let trackStatsArray = Array(trackStats.values)
        if let encoded = try? JSONEncoder().encode(trackStatsArray) {
            UserDefaults.standard.set(encoded, forKey: trackStatsKey)
        }
    }
    
    private func loadStats() {
        // Load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode(ListeningStats.self, from: data) {
            stats = decoded
        }
        
        if let data = UserDefaults.standard.data(forKey: trackStatsKey),
           let decoded = try? JSONDecoder().decode([TrackStatistics].self, from: data) {
            trackStats = Dictionary(uniqueKeysWithValues: decoded.map { ($0.path, $0) })
        }
    }
    
    func reset() {
        stats = ListeningStats()
        trackStats = [:]
        currentSession = nil
        saveStats()
    }
}

// Make ListeningStats and TrackStatistics Codable
extension ListeningStats: Codable {}
extension TrackStatistics: Codable {}
extension ListeningSession: Codable {}

