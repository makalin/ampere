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
        VStack(spacing: 8) {
            // Repeat and Shuffle controls
            HStack(spacing: 12) {
                // Repeat mode button (cycles: None -> One -> All)
                Button(action: cycleRepeatMode) {
                    HStack(spacing: 4) {
                        Image(systemName: repeatIcon)
                            .font(.system(size: 12))
                        Text(repeatText)
                            .font(.system(size: 8, design: .monospaced))
                    }
                    .foregroundColor(repeatColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(repeatColor.opacity(0.2))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                // Shuffle button
                Button(action: toggleShuffle) {
                    HStack(spacing: 4) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 12))
                        Text("SHUFFLE")
                            .font(.system(size: 8, design: .monospaced))
                    }
                    .foregroundColor(shuffleColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(shuffleColor.opacity(0.2))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Grouping button
                Button(action: { showingGrouping = true }) {
                    Text("GROUP")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.0, green: 0.6, blue: 0.0))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
                
                // Daily Suggestions button
                Button(action: { showingSuggestions = true }) {
                    Text("SUGGEST")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.0, green: 0.6, blue: 0.0))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
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
    }
    
    private func toggleShuffle() {
        guard let playlist = viewModel.playlist else { return }
        let current = playlist.getShuffleMode()
        playlist.setShuffleMode(current == .on ? .off : .on)
    }
    
    private var repeatMode: RepeatMode {
        viewModel.playlist?.getRepeatMode() ?? .none
    }
    
    private var repeatIcon: String {
        switch repeatMode {
        case .none: return "arrow.forward"
        case .one: return "repeat.1"
        case .all: return "repeat"
        }
    }
    
    private var repeatText: String {
        switch repeatMode {
        case .none: return "NONE"
        case .one: return "ONE"
        case .all: return "ALL"
        }
    }
    
    private var repeatColor: Color {
        repeatMode == .none ? .gray : Color(red: 0.0, green: 1.0, blue: 0.0)
    }
    
    private var shuffleColor: Color {
        viewModel.playlist?.getShuffleMode() == .on ? Color(red: 0.0, green: 1.0, blue: 0.0) : .gray
    }
}

