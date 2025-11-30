//
//  WinampWindows.swift
//  Ampere
//
//  Winamp-style EQ, Playlist, and Album Art windows
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct WinampEQWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar - draggable
            HStack {
                Text("Equalizer")
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
            .background(Color(red: 0.08, green: 0.08, blue: 0.12))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        dragOffset = .zero
                    }
            )
            
            // SPECTRUM ANALYZER - VISIBLE
            WinampEQDisplay(frequencyBands: Binding(
                get: { viewModel.eqSpectrumData },
                set: { _ in }
            ), width: 275, height: 80)
                .frame(width: 275, height: 80)
                .background(Color.black)
            
            // EQ sliders - WORKING
            HStack(spacing: 1) {
                ForEach(0..<10, id: \.self) { index in
                    WinampEQBand(index: index, viewModel: viewModel)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            
            // Presets
            HStack(spacing: 4) {
                winampSmallButton(action: { }, text: "PRE", width: 40)
                winampSmallButton(action: { }, text: "LOAD", width: 45)
                winampSmallButton(action: { }, text: "SAVE", width: 45)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.isEQEnabled() },
                    set: { viewModel.setEQEnabled($0) }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                Text("ON")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(4)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        }
        .frame(width: 275, height: 280)
        .background(winampGradient)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .offset(dragOffset)
    }
    
    private func winampSmallButton(action: @escaping () -> Void, text: String, width: CGFloat) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: width, height: 14)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                .cornerRadius(2)
        }
        .buttonStyle(.plain)
    }
    
    private var winampGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.18, green: 0.18, blue: 0.22), location: 0.0),
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.19), location: 0.5),
                    .init(color: Color(red: 0.12, green: 0.12, blue: 0.16), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle texture overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.03),
                            Color.clear,
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct WinampEQBand: View {
    let index: Int
    @ObservedObject var viewModel: PlayerViewModel
    @State private var gain: Float = 0.0
    @State private var isDragging: Bool = false
    
    private let bandLabels = ["60", "170", "310", "600", "1K", "3K", "6K", "12K", "14K", "16K"]
    
    var body: some View {
        VStack(spacing: 2) {
            // Frequency label
            Text(bandLabels[index])
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(height: 12)
            
            // Vertical slider - SIMPLE AND WORKING
            ZStack(alignment: .center) {
                // Track background
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                    .frame(width: 8, height: 120)
                    .overlay(
                        Rectangle()
                            .stroke(Color(red: 0.25, green: 0.25, blue: 0.3), lineWidth: 1)
                    )
                
                // Center line (0 dB)
                Rectangle()
                    .fill(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .frame(width: 8, height: 2)
                
                // Fill indicator
                let normalizedGain = (gain + 12.0) / 24.0 // 0.0 to 1.0
                let thumbY = CGFloat(1.0 - normalizedGain) * 120.0 - 60.0 // -60 to +60
                
                if gain > 0.1 {
                    // Positive gain - green above center
                    Rectangle()
                        .fill(Color(red: 0.0, green: 1.0, blue: 0.0))
                        .frame(width: 8, height: CGFloat(gain / 12.0) * 60.0)
                        .offset(y: -60.0 + (CGFloat(gain / 12.0) * 60.0) / 2.0)
                } else if gain < -0.1 {
                    // Negative gain - red below center
                    Rectangle()
                        .fill(Color(red: 1.0, green: 0.3, blue: 0.0))
                        .frame(width: 8, height: CGFloat(abs(gain) / 12.0) * 60.0)
                        .offset(y: 60.0 - (CGFloat(abs(gain) / 12.0) * 60.0) / 2.0)
                }
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color(red: 0.2, green: 0.2, blue: 0.3), lineWidth: 1)
                    )
                    .offset(y: thumbY)
            }
            .frame(width: 24, height: 120)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        let y = value.location.y
                        let normalized = 1.0 - (y / 120.0)
                        let clamped = max(0.0, min(1.0, normalized))
                        gain = Float(clamped * 24.0 - 12.0)
                        viewModel.setEQBand(index: index, gain: gain)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onTapGesture { location in
                let y = location.y
                let normalized = 1.0 - (y / 120.0)
                let clamped = max(0.0, min(1.0, normalized))
                gain = Float(clamped * 24.0 - 12.0)
                viewModel.setEQBand(index: index, gain: gain)
            }
            
            // Gain value
            Text(String(format: "%.0f", gain))
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(gain > 0 ? Color(red: 0.0, green: 1.0, blue: 0.0) : (gain < 0 ? Color(red: 1.0, green: 0.4, blue: 0.0) : .white))
                .frame(height: 12)
        }
        .frame(width: 26)
        .onAppear {
            // Load current gain value
            if let currentGain = viewModel.getEQBand(index: index) {
                gain = currentGain
            }
        }
        .onChange(of: viewModel.state) { _ in
            // Refresh gain when state changes
            if let currentGain = viewModel.getEQBand(index: index) {
                gain = currentGain
            }
        }
    }
}

struct WinampPlaylistWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Playlist")
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
            
            // Playlist items
            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    if let playlist = viewModel.playlist, !playlist.isEmpty() {
                        ForEach(0..<playlist.getLength(), id: \.self) { index in
                            WinampPlaylistItem(index: index, playlist: playlist, viewModel: viewModel)
                        }
                    } else {
                        Text("No tracks")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(8)
                    }
                }
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            
            // Controls
            VStack(spacing: 4) {
                HStack {
                    Button("ADD") { showingFilePicker = true }
                    Button("REM") { }
                    Button("SEL") { }
                    Spacer()
                    Button("MISC") { }
                    Button("SORT") { }
                }
                .padding(4)
                .background(Color(red: 0.1, green: 0.1, blue: 0.15))
                
                // Repeat, Shuffle, Grouping, Suggestions controls
                PlaylistControlsView(viewModel: viewModel)
                    .padding(4)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            }
        }
        .frame(width: 275, height: 300)
        .background(winampGradient)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                    provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                        if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                            DispatchQueue.main.async {
                                viewModel.addToPlaylist(path: url.path)
                            }
                        } else if let url = item as? URL {
                            DispatchQueue.main.async {
                                viewModel.addToPlaylist(path: url.path)
                            }
                        }
                    }
                }
            }
            return true
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                for url in urls {
                    let _ = url.startAccessingSecurityScopedResource()
                    viewModel.addToPlaylist(path: url.path)
                }
            }
        }
    }
    
    private var winampGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.18, green: 0.18, blue: 0.22), location: 0.0),
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.19), location: 0.5),
                    .init(color: Color(red: 0.12, green: 0.12, blue: 0.16), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle texture overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.03),
                            Color.clear,
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

struct WinampPlaylistItem: View {
    let index: Int
    let playlist: Playlist
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        let currentIndex = playlist.getCurrentTrackIndex()
        let isCurrent = currentIndex != nil && currentIndex! == index
        let track = playlist.getTrack(at: index)
        
        HStack {
            Text("\(index + 1).")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(isCurrent ? Color(red: 0.0, green: 1.0, blue: 0.0) : .white)
                .frame(width: 25)
            
            Text(URL(fileURLWithPath: track?.path ?? "").lastPathComponent)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(isCurrent ? Color(red: 0.0, green: 1.0, blue: 0.0) : .white)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(isCurrent ? Color(red: 0.2, green: 0.3, blue: 0.2) : Color.clear)
        .onTapGesture {
            if let track = track {
                // Set current index in playlist
                try? playlist.setCurrentTrackIndex(index)
                // Load and play
                viewModel.loadFile(path: track.path)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    viewModel.play()
                }
            }
        }
    }
}

struct WinampAlbumArtWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Album Art")
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
            
            if let albumArt = viewModel.metadata.albumArt {
                Image(nsImage: albumArt)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Rectangle()
                    .fill(Color(red: 0.15, green: 0.15, blue: 0.2))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
        }
        .frame(width: 208, height: 232)
        .background(winampGradient)
    }
    
    private var winampGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.18, green: 0.18, blue: 0.22), location: 0.0),
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.19), location: 0.5),
                    .init(color: Color(red: 0.12, green: 0.12, blue: 0.16), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Subtle texture overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.03),
                            Color.clear,
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

