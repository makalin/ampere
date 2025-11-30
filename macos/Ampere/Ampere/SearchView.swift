//
//  SearchView.swift
//  Ampere
//
//  Unified search interface for local and online music
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @StateObject private var searchService = OnlineSearchService()
    @State private var searchQuery = ""
    @State private var selectedSources: Set<SearchSource> = [.local, .spotify, .deezer, .youtube]
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Search Music")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
                    .onSubmit {
                        performSearch()
                    }
                
                Button(action: performSearch) {
                    Text("Search")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.0, green: 0.6, blue: 0.0))
                        .cornerRadius(2)
                }
            }
            .padding(8)
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            
            // Source selection
            HStack(spacing: 4) {
                Text("Sources:")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white)
                
                ForEach([SearchSource.local, .spotify, .deezer, .youtube], id: \.self) { source in
                    Button(action: {
                        if selectedSources.contains(source) {
                            selectedSources.remove(source)
                        } else {
                            selectedSources.insert(source)
                        }
                    }) {
                        Text(source.rawValue)
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(selectedSources.contains(source) ? .white : .gray)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(selectedSources.contains(source) ? Color(red: 0.0, green: 0.6, blue: 0.0) : Color(red: 0.2, green: 0.2, blue: 0.25))
                            .cornerRadius(2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.12, green: 0.12, blue: 0.16))
            
            // Results
            if searchService.isSearching {
                ProgressView()
                    .padding()
            } else if !searchService.searchResults.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(searchService.searchResults) { result in
                            SearchResultRow(result: result, viewModel: viewModel)
                        }
                    }
                    .padding(4)
                }
                .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            } else if !searchQuery.isEmpty {
                Text("No results found")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .frame(width: 500, height: 600)
        .background(winampGradient)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        Task {
            await searchService.search(query: searchQuery, sources: Array(selectedSources))
        }
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

struct SearchResultRow: View {
    let result: SearchResult
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        HStack {
            // Source indicator
            Text(result.source.rawValue.prefix(1))
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(sourceColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(result.artist)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if result.isLocal {
                Button(action: {
                    if let path = result.localPath {
                        viewModel.loadFile(path: path)
                        viewModel.play()
                    }
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    // Add to playlist or open in browser
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
        .cornerRadius(2)
    }
    
    private var sourceColor: Color {
        switch result.source {
        case .local: return .green
        case .spotify: return .green
        case .deezer: return .purple
        case .youtube: return .red
        }
    }
}

