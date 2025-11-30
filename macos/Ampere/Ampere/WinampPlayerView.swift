//
//  WinampPlayerView.swift
//  Ampere
//
//  Authentic Winamp-style player window - COMPLETE WORKING VERSION
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct WinampPlayerView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var showingEQ: Bool
    @Binding var showingPlaylist: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAlbumArt: Bool
    @Binding var showingLyrics: Bool
    @Binding var showingSearch: Bool
    @State private var showingFilePicker = false
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            winampTitleBar
            
            // Info display
            winampInfoDisplay
            
            // Controls
            winampControls
            
            // Time and progress - ALWAYS VISIBLE
            winampTimeDisplay
            
            // Spectrum analyzer
            winampSpectrum
            
            // Bottom buttons
            winampBottomButtons
        }
        .frame(width: 275, height: 116)
        .background(winampGradient)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleFilePickerResult(result)
        }
    }
    
    private func handleFilePickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                loadFileFromURL(url)
            }
        case .failure(let error):
            print("File picker error: \(error)")
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            self.loadFileFromURL(url)
                        }
                    } else if let url = item as? URL {
                        DispatchQueue.main.async {
                            self.loadFileFromURL(url)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func loadFileFromURL(_ url: URL) {
        // CRITICAL: Start accessing security-scoped resource BEFORE loading
        let _ = url.startAccessingSecurityScopedResource()
        
        // Store the URL in the viewModel so it stays accessible
        viewModel.loadFile(url: url)
        
        // Auto-play after loading with delay for file to be ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.play()
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
    
    private var winampTitleBar: some View {
        HStack(spacing: 0) {
            // Winamp logo
            HStack(spacing: 2) {
                Text("AMPER")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text("e")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.0))
            }
            .padding(.leading, 4)
            
            Spacer()
            
            // Window buttons
            HStack(spacing: 1) {
                winampWindowButton(action: { }, icon: "minus", size: 8)
                winampWindowButton(action: { }, icon: "square", size: 8)
                winampWindowButton(action: { NSApplication.shared.terminate(nil) }, icon: "xmark", size: 8)
            }
            .padding(.trailing, 2)
        }
        .frame(height: 14)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
    
    private var winampInfoDisplay: some View {
        HStack(spacing: 4) {
            // Mini visualization
            HStack(spacing: 1) {
                ForEach(0..<10, id: \.self) { index in
                    Rectangle()
                        .fill(Color(red: 0.0, green: 1.0, blue: 0.0))
                        .frame(width: 2, height: max(2, CGFloat(viewModel.spectrumData[index % 20])))
                        .animation(.linear(duration: 0.05), value: viewModel.spectrumData[index % 20])
                }
            }
            .frame(width: 25)
            
            // Track info
            VStack(alignment: .leading, spacing: 0) {
                Text(displayTitle)
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(height: 10)
                
                Text(displayArtist)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(height: 8)
            }
            
            Spacer()
            
            // Bitrate/KHz display
            Text("128 kbps")
                .font(.system(size: 6, design: .monospaced))
                .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(red: 0.12, green: 0.12, blue: 0.17))
    }
    
    private var displayTitle: String {
        if let title = viewModel.metadata.title, !title.isEmpty {
            return title
        }
        if let file = viewModel.currentFile {
            return URL(fileURLWithPath: file).lastPathComponent
        }
        return "No file loaded"
    }
    
    private var displayArtist: String {
        viewModel.metadata.artist ?? "Unknown Artist"
    }
    
    private var winampControls: some View {
        HStack(spacing: 4) {
            winampControlButton(action: { viewModel.playPrevious() }, icon: "backward.fill", size: 10)
            winampControlButton(action: { viewModel.playPrevious() }, icon: "backward.end.fill", size: 10)
            winampControlButton(
                action: {
                    if viewModel.state == .playing {
                        viewModel.pause()
                    } else {
                        if viewModel.currentFile == nil {
                            showingFilePicker = true
                        } else {
                            viewModel.play()
                        }
                    }
                },
                icon: viewModel.state == .playing ? "pause.fill" : "play.fill",
                size: 12
            )
            winampControlButton(action: { viewModel.stop() }, icon: "stop.fill", size: 10)
            winampControlButton(action: { viewModel.playNext() }, icon: "forward.end.fill", size: 10)
            winampControlButton(action: { viewModel.playNext() }, icon: "forward.fill", size: 10)
            
            Spacer()
            
            // Volume
            HStack(spacing: 2) {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.system(size: 6))
                    .foregroundColor(.white)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(red: 0.3, green: 0.3, blue: 0.35))
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(Color(red: 0.0, green: 1.0, blue: 0.0))
                            .frame(width: geometry.size.width * CGFloat(viewModel.volume), height: 4)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let newVolume = Float(value.location.x / geometry.size.width)
                                viewModel.setVolume(max(0, min(1, newVolume)))
                            }
                    )
                }
                .frame(width: 68, height: 4)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
    }
    
    private var winampTimeDisplay: some View {
        HStack(spacing: 4) {
            // Current time - ALWAYS VISIBLE
            Text(formatTime(viewModel.position))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .trailing)
                .background(Color.clear)
            
            // Progress slider - ALWAYS VISIBLE AND WORKING
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background - ALWAYS VISIBLE
                    Rectangle()
                        .fill(Color(red: 0.25, green: 0.25, blue: 0.3))
                        .frame(height: 6)
                    
                    // Progress bar
                    if let duration = viewModel.duration, duration > 0 {
                        let progress = min(1.0, max(0.0, viewModel.position / duration))
                        Rectangle()
                            .fill(Color(red: 0.0, green: 1.0, blue: 0.0))
                            .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                        
                        // Thumb/draggable circle
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .offset(x: geometry.size.width * CGFloat(progress) - 5, y: 0)
                    } else {
                        // Show empty track even if no duration
                        Rectangle()
                            .fill(Color(red: 0.0, green: 1.0, blue: 0.0))
                            .frame(width: 0, height: 6)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isDragging = true
                            if let duration = viewModel.duration, duration > 0 {
                                let newPosition = Double(value.location.x / geometry.size.width) * duration
                                let clampedPosition = max(0.0, min(newPosition, duration))
                                viewModel.seek(to: clampedPosition)
                            }
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .frame(height: 6)
            
            // Total duration - ALWAYS VISIBLE
            Text(formatTime(viewModel.duration ?? 0))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 40, alignment: .leading)
                .background(Color.clear)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .frame(height: 18)
        .background(Color(red: 0.12, green: 0.12, blue: 0.17))
    }
    
    private var winampSpectrum: some View {
        HStack(spacing: 1) {
            ForEach(0..<20, id: \.self) { index in
                Rectangle()
                    .fill(Color(red: 0.0, green: 1.0, blue: 0.0))
                    .frame(width: 12, height: max(2, CGFloat(viewModel.spectrumData[index])))
                    .animation(.linear(duration: 0.05), value: viewModel.spectrumData[index])
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(red: 0.08, green: 0.08, blue: 0.12))
        .frame(height: 18)
    }
    
    private var winampBottomButtons: some View {
        HStack(spacing: 2) {
            winampSmallButton(action: { showingFilePicker = true }, text: "LOAD", width: 35)
            winampSmallButton(action: { showingPlaylist.toggle() }, text: "LIST", width: 30)
            winampSmallButton(action: { showingEQ.toggle() }, text: "EQ", width: 25)
            winampSmallButton(action: { showingPlaylist.toggle() }, text: "PL", width: 25)
            winampSmallButton(action: { showingSettings.toggle() }, text: "SET", width: 30)
            winampSmallButton(action: { showingAlbumArt.toggle() }, text: "ART", width: 30)
            winampSmallButton(action: { showingLyrics.toggle() }, text: "LYR", width: 30)
            winampSmallButton(action: { showingSearch.toggle() }, text: "SRCH", width: 35)
            
            Spacer()
            
            // Shuffle/Repeat
            if viewModel.playlist?.getShuffleMode() == .on {
                Text("S")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.0))
            }
            if viewModel.playlist?.getRepeatMode() == .all {
                Text("R")
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.0))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
    }
    
    private func winampWindowButton(action: @escaping () -> Void, icon: String, size: CGFloat) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(.white)
                .frame(width: 12, height: 12)
        }
        .buttonStyle(.plain)
    }
    
    private func winampControlButton(action: @escaping () -> Void, icon: String, size: CGFloat) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                .cornerRadius(1)
        }
        .buttonStyle(.plain)
    }
    
    private func winampSmallButton(action: @escaping () -> Void, text: String, width: CGFloat) -> some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: width, height: 12)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                .cornerRadius(1)
        }
        .buttonStyle(.plain)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
