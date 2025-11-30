//
//  OnlineSearchService.swift
//  Ampere
//
//  Unified search for Spotify, Deezer, YouTube Music, and local files
//

import Foundation
import Combine

struct SearchResult: Identifiable {
    let id: String
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval?
    let source: SearchSource
    let url: String?
    let artworkURL: String?
    let isLocal: Bool
    let localPath: String?
}

enum SearchSource: String {
    case local = "Local"
    case spotify = "Spotify"
    case deezer = "Deezer"
    case youtube = "YouTube Music"
}

class OnlineSearchService: ObservableObject {
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching = false
    
    private let spotifyClientID = "YOUR_SPOTIFY_CLIENT_ID"
    private let spotifyClientSecret = "YOUR_SPOTIFY_CLIENT_SECRET"
    private let deezerAppID = "YOUR_DEEZER_APP_ID"
    
    func search(query: String, sources: [SearchSource] = [.local, .spotify, .deezer, .youtube]) async {
        await MainActor.run {
            isSearching = true
            searchResults = []
        }
        
        var allResults: [SearchResult] = []
        
        // Search local files
        if sources.contains(.local) {
            let localResults = await searchLocal(query: query)
            allResults.append(contentsOf: localResults)
        }
        
        // Search Spotify
        if sources.contains(.spotify) {
            let spotifyResults = await searchSpotify(query: query)
            allResults.append(contentsOf: spotifyResults)
        }
        
        // Search Deezer
        if sources.contains(.deezer) {
            let deezerResults = await searchDeezer(query: query)
            allResults.append(contentsOf: deezerResults)
        }
        
        // Search YouTube Music
        if sources.contains(.youtube) {
            let youtubeResults = await searchYouTube(query: query)
            allResults.append(contentsOf: youtubeResults)
        }
        
        await MainActor.run {
            searchResults = allResults
            isSearching = false
        }
    }
    
    private func searchLocal(query: String) async -> [SearchResult] {
        // Search local music files
        let fileManager = FileManager.default
        let searchPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Music"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")
        ]
        
        var results: [SearchResult] = []
        let queryLower = query.lowercased()
        
        for searchPath in searchPaths {
            guard let enumerator = fileManager.enumerator(at: searchPath, includingPropertiesForKeys: [.nameKey], options: [.skipsHiddenFiles]) else { continue }
            
            for case let fileURL as URL in enumerator {
                let fileName = fileURL.lastPathComponent.lowercased()
                if fileName.contains(queryLower) && ["mp3", "flac", "wav", "m4a", "aac", "ogg"].contains(fileURL.pathExtension.lowercased()) {
                    results.append(SearchResult(
                        id: fileURL.path,
                        title: fileURL.deletingPathExtension().lastPathComponent,
                        artist: "",
                        album: nil,
                        duration: nil,
                        source: .local,
                        url: nil,
                        artworkURL: nil,
                        isLocal: true,
                        localPath: fileURL.path
                    ))
                }
            }
        }
        
        return results
    }
    
    private func searchSpotify(query: String) async -> [SearchResult] {
        // Spotify API search (requires authentication)
        // This is a placeholder - you'll need to implement OAuth and API calls
        var results: [SearchResult] = []
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.spotify.com/v1/search?q=\(encodedQuery)&type=track&limit=20") else {
            return results
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // Add authorization header with access token
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tracks = json["tracks"] as? [String: Any],
               let items = tracks["items"] as? [[String: Any]] {
                for item in items {
                    let name = item["name"] as? String ?? ""
                    let artists = item["artists"] as? [[String: Any]] ?? []
                    let artist = artists.first?["name"] as? String ?? ""
                    let album = item["album"] as? [String: Any]
                    let albumName = album?["name"] as? String
                    let duration = Double(item["duration_ms"] as? Int ?? 0) / 1000.0
                    let spotifyURL = item["external_urls"] as? [String: String]
                    let spotifyLink = spotifyURL?["spotify"]
                    let images = album?["images"] as? [[String: Any]]
                    let artwork = images?.first?["url"] as? String
                    
                    results.append(SearchResult(
                        id: item["id"] as? String ?? UUID().uuidString,
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
        } catch {
            print("Spotify search error: \(error)")
        }
        
        return results
    }
    
    private func searchDeezer(query: String) async -> [SearchResult] {
        // Deezer API search
        var results: [SearchResult] = []
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.deezer.com/search?q=\(encodedQuery)") else {
            return results
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["data"] as? [[String: Any]] {
                for item in items {
                    let title = item["title"] as? String ?? ""
                    let artist = item["artist"] as? [String: Any]
                    let artistName = artist?["name"] as? String ?? ""
                    let album = item["album"] as? [String: Any]
                    let albumName = album?["title"] as? String
                    let duration = item["duration"] as? Int ?? 0
                    let deezerLink = item["link"] as? String
                    let artwork = item["album"] as? [String: Any]
                    let artworkURL = artwork?["cover_medium"] as? String
                    
                    results.append(SearchResult(
                        id: String(item["id"] as? Int ?? 0),
                        title: title,
                        artist: artistName,
                        album: albumName,
                        duration: TimeInterval(duration),
                        source: .deezer,
                        url: deezerLink,
                        artworkURL: artworkURL,
                        isLocal: false,
                        localPath: nil
                    ))
                }
            }
        } catch {
            print("Deezer search error: \(error)")
        }
        
        return results
    }
    
    private func searchYouTube(query: String) async -> [SearchResult] {
        // YouTube Music search (requires YouTube Data API)
        // This is a placeholder - you'll need to implement API calls
        var results: [SearchResult] = []
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedQuery)&type=video&maxResults=20&key=YOUR_YOUTUBE_API_KEY") else {
            return results
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let items = json["items"] as? [[String: Any]] {
                for item in items {
                    let snippet = item["snippet"] as? [String: Any] ?? [:]
                    let title = snippet["title"] as? String ?? ""
                    let channel = snippet["channelTitle"] as? String ?? ""
                    let videoId = item["id"] as? [String: Any]
                    let id = videoId?["videoId"] as? String ?? UUID().uuidString
                    let thumbnails = snippet["thumbnails"] as? [String: Any]
                    let artwork = thumbnails?["medium"] as? [String: Any]
                    let artworkURL = artwork?["url"] as? String
                    
                    results.append(SearchResult(
                        id: id,
                        title: title,
                        artist: channel,
                        album: nil,
                        duration: nil,
                        source: .youtube,
                        url: "https://www.youtube.com/watch?v=\(id)",
                        artworkURL: artworkURL,
                        isLocal: false,
                        localPath: nil
                    ))
                }
            }
        } catch {
            print("YouTube search error: \(error)")
        }
        
        return results
    }
    
    func importPlaylist(from source: SearchSource, playlistID: String) async -> [SearchResult] {
        // Import playlist from online service
        // Implementation depends on each service's API
        return []
    }
    
    func exportPlaylist(to source: SearchSource, results: [SearchResult]) async -> Bool {
        // Export playlist to online service
        // Implementation depends on each service's API
        return false
    }
}

