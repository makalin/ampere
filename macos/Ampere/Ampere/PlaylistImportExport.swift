//
//  PlaylistImportExport.swift
//  Ampere
//
//  Import/Export playlists from Spotify, Deezer, YouTube Music
//

import Foundation

class PlaylistImportExport {
    
    func importFromSpotify(playlistID: String, accessToken: String) async throws -> [SearchResult] {
        guard let url = URL(string: "https://api.spotify.com/v1/playlists/\(playlistID)/tracks") else {
            throw NSError(domain: "PlaylistImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let items = json["items"] as? [[String: Any]] else {
            throw NSError(domain: "PlaylistImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        var results: [SearchResult] = []
        for item in items {
            if let track = item["track"] as? [String: Any] {
                let name = track["name"] as? String ?? ""
                let artists = track["artists"] as? [[String: Any]] ?? []
                let artist = artists.first?["name"] as? String ?? ""
                let album = track["album"] as? [String: Any]
                let albumName = album?["name"] as? String
                let duration = Double(track["duration_ms"] as? Int ?? 0) / 1000.0
                let spotifyURL = track["external_urls"] as? [String: String]
                let spotifyLink = spotifyURL?["spotify"]
                let images = album?["images"] as? [[String: Any]]
                let artwork = images?.first?["url"] as? String
                
                results.append(SearchResult(
                    id: track["id"] as? String ?? UUID().uuidString,
                    title: name,
                    artist: artist,
                    album: albumName,
                    duration: duration,
                    source: .spotify,
                    url: spotifyLink,
                    artworkURL: artwork,
                    isLocal: false,
                    localPath: nil
                ))
            }
        }
        
        return results
    }
    
    func importFromDeezer(playlistID: String) async throws -> [SearchResult] {
        guard let url = URL(string: "https://api.deezer.com/playlist/\(playlistID)") else {
            throw NSError(domain: "PlaylistImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tracks = json["tracks"] as? [String: Any],
              let items = tracks["data"] as? [[String: Any]] else {
            throw NSError(domain: "PlaylistImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        var results: [SearchResult] = []
        for item in items {
            let title = item["title"] as? String ?? ""
            let artist = item["artist"] as? [String: Any]
            let artistName = artist?["name"] as? String ?? ""
            let album = item["album"] as? [String: Any]
            let albumName = album?["title"] as? String
            let duration = item["duration"] as? Int ?? 0
            let deezerLink = item["link"] as? String
            let artwork = album?["cover_medium"] as? String
            
            results.append(SearchResult(
                id: String(item["id"] as? Int ?? 0),
                title: title,
                artist: artistName,
                album: albumName,
                duration: TimeInterval(duration),
                source: .deezer,
                url: deezerLink,
                artworkURL: artwork,
                isLocal: false,
                localPath: nil
            ))
        }
        
        return results
    }
    
    func exportToSpotify(playlistName: String, tracks: [SearchResult], accessToken: String) async throws -> String {
        // Create playlist
        guard let url = URL(string: "https://api.spotify.com/v1/me/playlists") else {
            throw NSError(domain: "PlaylistExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["name": playlistName, "public": false]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let playlistID = json["id"] as? String else {
            throw NSError(domain: "PlaylistExport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create playlist"])
        }
        
        // Add tracks (requires track URIs)
        // Implementation depends on having track URIs from Spotify
        
        return playlistID
    }
}

