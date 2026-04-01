//
//  WinampWindows.swift
//  Ampere
//
//  EQ, Playlist, and Album Art sub-windows — bitmap Winamp style
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// ─── MARK: Shared Winamp Sub-Window Frame ────────────────────────────────────

struct AmpWindowFrame<Content: View>: View {
    let title: String
    let width: CGFloat
    let height: CGFloat
    let onClose: () -> Void
    let content: Content

    init(
        title: String,
        width: CGFloat,
        height: CGFloat,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.width = width
        self.height = height
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 4) {
                Text("⚡")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(AmpColor.amber)
                Text(title)
                    .font(.ampMono(8, weight: .bold))
                    .foregroundColor(AmpColor.neonGreen)
                    .kerning(1)
                    .shadow(color: AmpColor.neonGreen.opacity(0.5), radius: 2)
                Spacer()
                Button(action: onClose) {
                    ZStack {
                        AmpColor.panelLight
                        Text("✕")
                            .font(.ampMono(7, weight: .bold))
                            .foregroundColor(AmpColor.textBright)
                    }
                    .frame(width: 12, height: 12)
                    .overlay(
                        ZStack {
                            VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
                            HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .frame(height: 16)
            .background(
                LinearGradient(
                    colors: [AmpColor.panelMid, AmpColor.panelDeep],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(Rectangle().fill(AmpColor.bevelShadow).frame(height: 1), alignment: .bottom)

            content
        }
        .frame(width: width, height: height)
        .background(AmpColor.panelDeep)
        .overlay(
            ZStack {
                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
            }
        )
        .shadow(color: .black.opacity(0.75), radius: 12, x: 3, y: 5)
    }
}

// ─── MARK: EQ Window ─────────────────────────────────────────────────────────

struct WinampEQWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        AmpWindowFrame(title: "EQUALIZER", width: 275, height: 260, onClose: { isPresented = false }) {
            VStack(spacing: 0) {
                // Spectrum display
                BevelBox(style: .inset) {
                    WinampEQDisplay(
                        frequencyBands: Binding(
                            get: { viewModel.eqSpectrumData },
                            set: { _ in }
                        ),
                        width: 275,
                        height: 72
                    )
                    .background(AmpColor.displayBg)
                }
                .frame(height: 72)

                // EQ band sliders
                HStack(spacing: 1) {
                    ForEach(0..<10, id: \.self) { i in
                        WinampEQBand(index: i, viewModel: viewModel)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
                .background(AmpColor.panelDark)
                .overlay(Rectangle().fill(AmpColor.bevelShadow).frame(height: 1), alignment: .bottom)

                // Preset + EQ on/off bar
                HStack(spacing: 3) {
                    AmpButton(label: "PRESET", width: 44, height: 14) {}
                    AmpButton(label: "LOAD",   width: 36, height: 14) {}
                    AmpButton(label: "SAVE",   width: 36, height: 14) {}
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.isEQEnabled() },
                        set: { viewModel.setEQEnabled($0) }
                    ))
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(AmpColor.neonGreen)
                    Text("EQ")
                        .font(.ampMono(7, weight: .bold))
                        .foregroundColor(viewModel.isEQEnabled() ? AmpColor.neonGreen : AmpColor.textDim)
                        .shadow(color: viewModel.isEQEnabled() ? AmpColor.neonGreen.opacity(0.8) : .clear, radius: 2)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(AmpColor.panelDeep)
            }
        }
    }
}

// ─── MARK: EQ Band ───────────────────────────────────────────────────────────

struct WinampEQBand: View {
    let index: Int
    @ObservedObject var viewModel: PlayerViewModel
    @State private var gain: Float = 0.0
    private let bandLabels = ["60", "170", "310", "600", "1K", "3K", "6K", "12K", "14K", "16K"]

    var body: some View {
        VStack(spacing: 2) {
            Text(bandLabels[index])
                .font(.ampMono(6, weight: .bold))
                .foregroundColor(AmpColor.textMid)
                .frame(height: 10)

            BevelBox(style: .inset) {
                GeometryReader { geo in
                    let h = geo.size.height
                    let normalized = CGFloat((gain + 12.0) / 24.0)
                    let thumbY = (1.0 - normalized) * h

                    ZStack(alignment: .top) {
                        AmpColor.displayBg

                        // Zero dB line
                        Rectangle()
                            .fill(AmpColor.textDim)
                            .frame(width: 18, height: 1)
                            .offset(y: h / 2)

                        // Gain fill
                        if gain > 0.1 {
                            AmpColor.neonGreenDim
                                .frame(width: 6, height: CGFloat(gain / 12.0) * h / 2)
                                .offset(x: 6, y: h / 2 - CGFloat(gain / 12.0) * h / 2)
                        } else if gain < -0.1 {
                            Color(red: 0.8, green: 0.2, blue: 0)
                                .opacity(0.6)
                                .frame(width: 6, height: CGFloat(abs(gain) / 12.0) * h / 2)
                                .offset(x: 6, y: h / 2)
                        }

                        // Thumb
                        ZStack {
                            Rectangle().fill(AmpColor.panelLight).frame(width: 18, height: 8)
                            Rectangle().fill(AmpColor.neonGreenDim).frame(width: 10, height: 2)
                        }
                        .overlay(
                            ZStack {
                                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer() }
                                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer() }
                            }
                        )
                        .offset(y: thumbY - 4)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let clamped = max(0, min(1, Float(val.location.y / h)))
                                gain = (1.0 - clamped) * 24.0 - 12.0
                                viewModel.setEQBand(index: index, gain: gain)
                            }
                    )
                }
                .frame(width: 20, height: 110)
            }

            Text(String(format: "%+.0f", gain))
                .font(.ampMono(6, weight: .bold))
                .foregroundColor(gain > 0 ? AmpColor.neonGreen : (gain < 0 ? AmpColor.amber : AmpColor.textDim))
                .frame(height: 10)
        }
        .frame(width: 24)
        .onAppear {
            if let g = viewModel.getEQBand(index: index) { gain = g }
        }
    }
}

// ─── MARK: Playlist Window ────────────────────────────────────────────────────

struct WinampPlaylistWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool
    @State private var showingFilePicker = false

    var body: some View {
        AmpWindowFrame(title: "PLAYLIST", width: 275, height: 300, onClose: { isPresented = false }) {
            VStack(spacing: 0) {
                // Track list
                BevelBox(style: .inset) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            if let pl = viewModel.playlist, !pl.isEmpty() {
                                ForEach(0..<pl.getLength(), id: \.self) { i in
                                    WinampPlaylistItem(index: i, playlist: pl, viewModel: viewModel)
                                }
                            } else {
                                HStack {
                                    Text("⚡ Drop audio files here…")
                                        .font(.ampMono(8))
                                        .foregroundColor(AmpColor.textDim)
                                    Spacer()
                                }
                                .padding(8)
                            }
                        }
                    }
                    .background(AmpColor.displayBg)
                }
                .frame(height: 220)

                // Separator
                Rectangle().fill(AmpColor.bevelShadow).frame(height: 1)

                // Controls
                VStack(spacing: 3) {
                    HStack(spacing: 3) {
                        AmpButton(label: "ADD",  width: 36, height: 14) { showingFilePicker = true }
                        AmpButton(label: "REM",  width: 36, height: 14) {}
                        AmpButton(label: "SEL",  width: 36, height: 14) {}
                        Spacer()
                        AmpButton(label: "SORT", width: 36, height: 14) {}
                        AmpButton(label: "MISC", width: 36, height: 14) {}
                    }
                    PlaylistControlsView(viewModel: viewModel)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 4)
                .background(AmpColor.panelDeep)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for p in providers {
                p.loadItem(forTypeIdentifier: "public.file-url") { item, _ in
                    let url = (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) } ?? (item as? URL)
                    if let url { DispatchQueue.main.async { viewModel.addToPlaylist(path: url.path) } }
                }
            }
            return true
        }
        .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
            if case .success(let urls) = result {
                for url in urls {
                    let _ = url.startAccessingSecurityScopedResource()
                    viewModel.addToPlaylist(path: url.path)
                }
            }
        }
    }
}

// ─── MARK: Playlist Item ─────────────────────────────────────────────────────

struct WinampPlaylistItem: View {
    let index: Int
    let playlist: Playlist
    @ObservedObject var viewModel: PlayerViewModel

    var body: some View {
        let current = playlist.getCurrentTrackIndex()
        let isCurrent = current != nil && current! == index
        let track = playlist.getTrack(at: index)

        HStack(spacing: 0) {
            // Track number
            Text(String(format: "%02d.", index + 1))
                .font(.ampMono(7, weight: .bold))
                .foregroundColor(isCurrent ? AmpColor.amber : AmpColor.textDim)
                .frame(width: 26, alignment: .trailing)
                .padding(.trailing, 4)

            // Track name
            Text(URL(fileURLWithPath: track?.path ?? "").lastPathComponent)
                .font(.ampMono(7.5))
                .foregroundColor(isCurrent ? AmpColor.neonGreen : AmpColor.textBright)
                .shadow(color: isCurrent ? AmpColor.neonGreen.opacity(0.6) : .clear, radius: 2)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            if isCurrent {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 7))
                    .foregroundColor(AmpColor.neonGreen)
                    .shadow(color: AmpColor.neonGreen.opacity(0.8), radius: 2)
                    .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 3)
        .padding(.leading, 4)
        .background(isCurrent ? AmpColor.panelMid : Color.clear)
        .overlay(
            Rectangle()
                .fill(isCurrent ? AmpColor.neonGreenDim : Color.clear)
                .frame(width: 2),
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let track {
                try? playlist.setCurrentTrackIndex(index)
                viewModel.loadFile(path: track.path)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { viewModel.play() }
            }
        }
    }
}

// ─── MARK: Album Art Window ───────────────────────────────────────────────────

struct WinampAlbumArtWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        AmpWindowFrame(title: "ALBUM ART", width: 210, height: 236, onClose: { isPresented = false }) {
            BevelBox(style: .inset) {
                Group {
                    if let art = viewModel.metadata.albumArt {
                        Image(nsImage: art)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 208, height: 208)
                            .clipped()
                    } else {
                        ZStack {
                            AmpColor.displayBg
                            VStack(spacing: 6) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 44))
                                    .foregroundColor(AmpColor.neonGreenDim)
                                    .shadow(color: AmpColor.neonGreen.opacity(0.5), radius: 8)
                                Text("NO COVER ART")
                                    .font(.ampMono(7, weight: .bold))
                                    .foregroundColor(AmpColor.textDim)
                                    .kerning(2)
                            }
                        }
                        .frame(width: 208, height: 208)
                    }
                }
            }
        }
    }
}
