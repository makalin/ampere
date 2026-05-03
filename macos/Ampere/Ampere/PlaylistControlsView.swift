//
//  PlaylistControlsView.swift
//  Ampere
//
//  Repeat, Shuffle, and Playlist controls
//

import SwiftUI

struct PlaylistControlsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @State private var showingGrouping = false
    @State private var showingSuggestions = false
    
    var body: some View {
        HStack(spacing: 3) {
            // Text-only (same as ADD/REM) — avoids icon+label wrapping (“NON E”) on macOS.
            AmpButton(
                label: repeatText,
                isActive: repeatMode != .none,
                width: 38,
                height: 14,
                action: cycleRepeatMode
            )
            AmpButton(
                label: "SHUFFLE",
                isActive: viewModel.playlist?.getShuffleMode() == .on,
                width: 52,
                height: 14,
                action: toggleShuffle
            )
            Spacer()
            AmpButton(label: "GROUP", width: 42, height: 14) { showingGrouping = true }
            AmpButton(label: "SUGGEST", width: 52, height: 14) { showingSuggestions = true }
        }
        .sheet(isPresented: $showingGrouping) {
            PlaylistGroupingView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingSuggestions) {
            DailySuggestionsView(viewModel: viewModel)
        }
    }
    
    private func cycleRepeatMode() {
        guard let playlist = viewModel.playlist else { return }
        let current = playlist.getRepeatMode()
        switch current {
        case .none:
            playlist.setRepeatMode(.one)
        case .one:
            playlist.setRepeatMode(.all)
        case .all:
            playlist.setRepeatMode(.none)
        }
        viewModel.notifyPlaylistUIChanged()
    }
    
    private func toggleShuffle() {
        guard let playlist = viewModel.playlist else { return }
        let current = playlist.getShuffleMode()
        playlist.setShuffleMode(current == .on ? .off : .on)
        viewModel.notifyPlaylistUIChanged()
    }
    
    private var repeatMode: RepeatMode {
        viewModel.playlist?.getRepeatMode() ?? .none
    }
    
    private var repeatText: String {
        switch repeatMode {
        case .none: return "NONE"
        case .one: return "ONE"
        case .all: return "ALL"
        }
    }
    
}

