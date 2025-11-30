//
//  DailySuggestionsView.swift
//  Ampere
//
//  Daily music suggestions interface
//

import SwiftUI
import UniformTypeIdentifiers

struct DailySuggestionsView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var suggestions: DailySuggestions
    @State private var showingExport = false
    
    init(viewModel: PlayerViewModel) {
        self.viewModel = viewModel
        _suggestions = StateObject(wrappedValue: DailySuggestions(playlist: viewModel.playlist))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Daily Suggestions")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showingExport = true }) {
                    Text("EXPORT")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.0, green: 0.6, blue: 0.0))
                        .cornerRadius(2)
                }
                .buttonStyle(.plain)
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            // Daily Playlist section
            VStack(alignment: .leading, spacing: 4) {
                Text("TODAY'S PLAYLIST")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(suggestions.dailyPlaylist) { track in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    HStack {
                                        Text(track.artist)
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.gray)
                                        Text("• \(track.reason)")
                                            .font(.system(size: 7, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.loadFile(path: track.path)
                                    viewModel.play()
                                    suggestions.recordPlay(trackPath: track.path)
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
                    }
                    .padding(8)
                }
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        }
        .frame(width: 500, height: 600)
        .background(winampGradient)
        .cornerRadius(4)
        .fileExporter(
            isPresented: $showingExport,
            document: PlaylistDocument(content: suggestions.exportDailyPlaylist()),
            contentType: .plainText,
            defaultFilename: "Daily_Playlist_\(Date().formatted(date: .numeric, time: .omitted)).m3u"
        ) { result in
            if case .success(let url) = result {
                try? suggestions.saveDailyPlaylist(to: url)
            }
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

struct PlaylistDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    var content: String
    
    init(content: String) {
        self.content = content
    }
    
    init(configuration: ReadConfiguration) throws {
        content = String(data: configuration.file.regularFileContents ?? Data(), encoding: .utf8) ?? ""
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: content.data(using: .utf8) ?? Data())
    }
}

