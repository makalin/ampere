//
//  Playlist.swift
//  Ampere
//
//  Playlist management
//

import Foundation

enum RepeatMode {
    case none
    case one
    case all
}

enum ShuffleMode {
    case off
    case on
}

struct PlaylistEntry {
    let path: String
    let title: String?
    let artist: String?
    let album: String?
    let duration: Double?
    let genre: String?
    let year: Int?
}

class Playlist {
    private var entries: [PlaylistEntry] = []
    private var currentIndex: Int? = nil
    private var shuffleOrder: [Int] = []
    private var repeatMode: RepeatMode = .none
    private var shuffleMode: ShuffleMode = .off
    
    init() {
        rebuildShuffleOrder()
        loadFromPersistence()
    }
    
    private func loadFromPersistence() {
        let (tracks, savedIndex, savedRepeatMode, savedShuffleMode) = PlaylistPersistence.loadPlaylist()
        
        // Restore tracks
        entries = tracks
        currentIndex = savedIndex
        repeatMode = savedRepeatMode
        shuffleMode = savedShuffleMode
        
        rebuildShuffleOrder()
    }
    
    func saveToPersistence() {
        PlaylistPersistence.savePlaylist(self)
    }
    
    func addFile(path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw NSError(domain: "Playlist", code: 1, userInfo: [NSLocalizedDescriptionKey: "File does not exist"])
        }
        
        // Try to extract metadata
        let metadata = MetadataExtractor.extractMetadata(from: path)
        
        let entry = PlaylistEntry(
            path: path,
            title: metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.duration,
            genre: metadata.genre,
            year: metadata.year
        )
        
        entries.append(entry)
        rebuildShuffleOrder()
        saveToPersistence() // Save when playlist changes
    }
    
    func removeFile(at index: Int) throws {
        guard index >= 0 && index < entries.count else {
            throw NSError(domain: "Playlist", code: 2, userInfo: [NSLocalizedDescriptionKey: "Index out of range"])
        }
        
        entries.remove(at: index)
        rebuildShuffleOrder()
    }
    
    func clear() {
        entries.removeAll()
        currentIndex = nil
        shuffleOrder.removeAll()
    }
    
    func getCurrentTrackIndex() -> Int? {
        return currentIndex
    }
    
    func setCurrentTrackIndex(_ index: Int) throws {
        guard index >= 0 && index < entries.count else {
            throw NSError(domain: "Playlist", code: 2, userInfo: [NSLocalizedDescriptionKey: "Index out of range"])
        }
        currentIndex = index
        saveToPersistence() // Save when track changes
    }
    
    func getCurrentTrack() -> PlaylistEntry? {
        guard let index = currentIndex, index < entries.count else { return nil }
        return entries[index]
    }
    
    func getNextTrack() -> PlaylistEntry? {
        guard !entries.isEmpty else { return nil }
        
        if shuffleMode == .on && !shuffleOrder.isEmpty {
            guard let current = currentIndex else {
                currentIndex = shuffleOrder.first
                return getCurrentTrack()
            }
            
            if let currentShuffleIndex = shuffleOrder.firstIndex(of: current) {
                let nextShuffleIndex = (currentShuffleIndex + 1) % shuffleOrder.count
                currentIndex = shuffleOrder[nextShuffleIndex]
            } else {
                currentIndex = shuffleOrder.first
            }
        } else {
            if let current = currentIndex {
                if current < entries.count - 1 {
                    currentIndex = current + 1
                } else if repeatMode == .all {
                    currentIndex = 0
                } else {
                    return nil
                }
            } else {
                currentIndex = 0
            }
        }
        
        return getCurrentTrack()
    }
    
    func getPreviousTrack() -> PlaylistEntry? {
        guard !entries.isEmpty else { return nil }
        
        if shuffleMode == .on && !shuffleOrder.isEmpty {
            guard let current = currentIndex else {
                currentIndex = shuffleOrder.last
                return getCurrentTrack()
            }
            
            if let currentShuffleIndex = shuffleOrder.firstIndex(of: current) {
                let prevShuffleIndex = currentShuffleIndex == 0 ? shuffleOrder.count - 1 : currentShuffleIndex - 1
                currentIndex = shuffleOrder[prevShuffleIndex]
            } else {
                currentIndex = shuffleOrder.last
            }
        } else {
            if let current = currentIndex {
                if current > 0 {
                    currentIndex = current - 1
                } else if repeatMode == .all {
                    currentIndex = entries.count - 1
                } else {
                    return nil
                }
            } else {
                currentIndex = entries.count - 1
            }
        }
        
        return getCurrentTrack()
    }
    
    func getLength() -> Int {
        return entries.count
    }
    
    func isEmpty() -> Bool {
        return entries.isEmpty
    }
    
    func setRepeatMode(_ mode: RepeatMode) {
        repeatMode = mode
    }
    
    func getRepeatMode() -> RepeatMode {
        return repeatMode
    }
    
    func setShuffleMode(_ mode: ShuffleMode) {
        shuffleMode = mode
        rebuildShuffleOrder()
    }
    
    func getShuffleMode() -> ShuffleMode {
        return shuffleMode
    }
    
    func getTrack(at index: Int) -> PlaylistEntry? {
        guard index >= 0 && index < entries.count else { return nil }
        return entries[index]
    }
    
    private func rebuildShuffleOrder() {
        shuffleOrder = Array(0..<entries.count).shuffled()
    }
}

