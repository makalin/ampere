//
//  PlaylistGrouping.swift
//  Ampere
//
//  Playlist grouping and organization features
//

import Foundation

enum GroupingType: String, CaseIterable {
    case artist = "Artist"
    case album = "Album"
    case genre = "Genre"
    case year = "Year"
    case dateAdded = "Date Added"
    case playCount = "Play Count"
    case rating = "Rating"
}

struct PlaylistGroup {
    let name: String
    let tracks: [PlaylistEntry]
}

class PlaylistGrouping {
    private let playlist: Playlist
    
    init(playlist: Playlist) {
        self.playlist = playlist
    }
    
    func group(by type: GroupingType) -> [PlaylistGroup] {
        var groups: [String: [PlaylistEntry]] = [:]
        
        for i in 0..<playlist.getLength() {
            guard let track = playlist.getTrack(at: i) else { continue }
            
            let key: String
            switch type {
            case .artist:
                key = track.artist ?? "Unknown Artist"
            case .album:
                key = track.album ?? "Unknown Album"
            case .genre:
                key = track.genre ?? "Unknown Genre"
            case .year:
                key = track.year.map { String($0) } ?? "Unknown Year"
            case .dateAdded:
                // Would need to track date added
                key = "Recently Added"
            case .playCount:
                let count = UserDefaults.standard.integer(forKey: "playCount_\(track.path)")
                key = count > 10 ? "Favorites" : count > 0 ? "Played" : "Unplayed"
            case .rating:
                // Would need rating system
                key = "Unrated"
            }
            
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(track)
        }
        
        return groups.map { PlaylistGroup(name: $0.key, tracks: $0.value) }
            .sorted { $0.name < $1.name }
    }
    
    func searchInGroups(groups: [PlaylistGroup], query: String) -> [PlaylistGroup] {
        let queryLower = query.lowercased()
        return groups.compactMap { group in
            let matchingTracks = group.tracks.filter { track in
                let title = track.title?.lowercased() ?? ""
                let artist = track.artist?.lowercased() ?? ""
                return title.contains(queryLower) || artist.contains(queryLower)
            }
            return matchingTracks.isEmpty ? nil : PlaylistGroup(name: group.name, tracks: matchingTracks)
        }
    }
}

