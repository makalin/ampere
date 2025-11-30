//
//  PlaylistGroupingView.swift
//  Ampere
//
//  Playlist grouping interface
//

import SwiftUI

struct PlaylistGroupingView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGrouping: GroupingType = .artist
    @State private var searchQuery = ""
    
    private var grouping: PlaylistGrouping? {
        guard let playlist = viewModel.playlist else { return nil }
        return PlaylistGrouping(playlist: playlist)
    }
    
    private var groups: [PlaylistGroup] {
        guard let grouping = grouping else { return [] }
        let allGroups = grouping.group(by: selectedGrouping)
        if searchQuery.isEmpty {
            return allGroups
        } else {
            return grouping.searchInGroups(groups: allGroups, query: searchQuery)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Playlist Grouping")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            // Grouping type selector
            Picker("Group by", selection: $selectedGrouping) {
                ForEach(GroupingType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            
            // Groups
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(groups, id: \.name) { group in
                        DisclosureGroup {
                            ForEach(Array(group.tracks.enumerated()), id: \.offset) { index, track in
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(.gray)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(track.title ?? URL(fileURLWithPath: track.path).lastPathComponent)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        if let artist = track.artist {
                                            Text(artist)
                                                .font(.system(size: 8, design: .monospaced))
                                                .foregroundColor(.gray)
                                                .lineLimit(1)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        viewModel.loadFile(path: track.path)
                                        viewModel.play()
                                    }) {
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.green)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                .cornerRadius(2)
                            }
                        } label: {
                            HStack {
                                Text(group.name)
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(group.tracks.count) tracks")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(8)
                        .background(Color(red: 0.18, green: 0.18, blue: 0.22))
                        .cornerRadius(4)
                    }
                }
                .padding(8)
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        }
        .frame(width: 600, height: 700)
        .background(winampGradient)
        .cornerRadius(4)
    }
    
    private var winampGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.18, green: 0.18, blue: 0.22), location: 0.0),
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.19), location: 0.5),
                    .init(color: Color(red: 0.12, green: 0.12, blue: 0.16), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

