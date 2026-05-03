//
//  WinampPlayerView.swift
//  Ampere
//
//  Full bitmap-style Winamp UI — redesigned with AmpereDesignSystem
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct WinampPlayerView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @EnvironmentObject var live: PlayerLiveState
    @Binding var showingEQ: Bool
    @Binding var showingPlaylist: Bool
    @Binding var showingSettings: Bool
    @Binding var showingAlbumArt: Bool
    @Binding var showingLyrics: Bool
    @Binding var showingSearch: Bool
    @Binding var showingPro: Bool
    @State private var showingFilePicker = false
    @State private var isDragging = false
    /// While scrubbing, show this position so the timer doesn’t fight the thumb.
    @State private var seekPreviewSeconds: Double?

    var body: some View {
        // Leading alignment: rows narrower than 304pt were centered by default VStack and showed side gutters.
        VStack(alignment: .leading, spacing: 0) {
            titleBar
            displayPanel
            seekAndTime
            controlBar
            bottomBar
        }
        .frame(width: AmpChrome.windowWidth, height: 116, alignment: .topLeading)
        .background(AmpColor.panelDeep)
        // Keep blur tight — large bottom-offset shadow reads as a gap above the playlist.
        .shadow(color: .black.opacity(0.55), radius: 5, x: 0, y: 2)
        .onDrop(of: [.fileURL], isTargeted: nil, perform: handleDrop)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                loadFileFromURL(url)
            }
        }
    }

    // ─── Title Bar ───────────────────────────────────────────────────────────

    private var titleBar: some View {
        HStack(spacing: 0) {
            // Logo
            HStack(spacing: 3) {
                // Lightning bolt in amber
                Text("⚡")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(AmpColor.amber)
                    .shadow(color: AmpColor.amber.opacity(0.8), radius: 3)
                Text("AMPERE")
                    .font(.ampMono(8, weight: .black))
                    .foregroundColor(AmpColor.neonGreen)
                    .shadow(color: AmpColor.neonGreen.opacity(0.7), radius: 3)
                    .kerning(1.5)
            }
            .padding(.leading, 6)

            Spacer()

            // Clock-like indicator dots
            HStack(spacing: 3) {
                Circle()
                    .fill(viewModel.state == .playing ? AmpColor.neonGreen : AmpColor.neonGreenFade)
                    .frame(width: 4, height: 4)
                    .shadow(color: viewModel.state == .playing ? AmpColor.neonGreen : .clear, radius: 3)
                Circle()
                    .fill(viewModel.state == .paused ? AmpColor.amber : AmpColor.neonGreenFade)
                    .frame(width: 4, height: 4)
            }
            .padding(.trailing, 6)

            // Window controls — pixel button style
            HStack(spacing: 1) {
                titleBarButton(color: AmpColor.amber)     { /* minimize */ }
                titleBarButton(color: AmpColor.neonGreen) { /* shade */ }
                titleBarButton(color: Color.red.opacity(0.85)) { NSApplication.shared.terminate(nil) }
            }
            .padding(.trailing, 4)
        }
        .frame(height: 14)
        .background(
            LinearGradient(
                colors: [AmpColor.panelMid, AmpColor.panelDeep],
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(
            Rectangle().fill(AmpColor.bevelShadow).frame(height: 1),
            alignment: .bottom
        )
        .frame(width: AmpChrome.windowWidth, alignment: .leading)
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
    }

    private func titleBarButton(color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                AmpColor.panelLight
                color.opacity(0.75)
            }
            .frame(width: 9, height: 9)
            .overlay(
                ZStack {
                    VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer() }
                    HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer() }
                    VStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
                    HStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // ─── Display Panel (LCD + visualizer) ────────────────────────────────────

    private var displayPanel: some View {
        HStack(spacing: 0) {

            // Left: mini spectrum
            BevelBox(style: .inset) {
                MiniSpectrumView(
                    bands: miniSpectrumBands,
                    isActive: viewModel.state == .playing
                )
                .frame(width: 22, height: 24)
                .background(AmpColor.displayBg)
                .clipped()
            }
            .padding(.leading, 2)
            .padding(.vertical, 3)

            // Center: LCD fills all space between spectrum and bitrate columns
            BevelBox(style: .inset) {
                GeometryReader { geo in
                    let innerW = max(40, geo.size.width - 8)
                    ZStack(alignment: .topLeading) {
                        LcdBackground()
                            .frame(width: geo.size.width, height: geo.size.height)
                        VStack(alignment: .leading, spacing: 1) {
                            MarqueeText(
                                text: displayTitle,
                                font: .ampMono(8, weight: .semibold),
                                color: AmpColor.neonGreen,
                                width: innerW
                            )
                            Text(displayArtist)
                                .font(.ampMono(6.5))
                                .foregroundColor(AmpColor.textMid)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .frame(width: geo.size.width, alignment: .leading)
                    }
                }
                .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 2)
            .padding(.vertical, 3)

            // Right: bit/kHz readout
            BevelBox(style: .inset) {
                VStack(spacing: 1) {
                    Text("128")
                        .font(.ampDigital(9))
                        .foregroundColor(AmpColor.neonGreen)
                        .shadow(color: AmpColor.neonGreen.opacity(0.6), radius: 2)
                    Text("kbps")
                        .font(.ampMono(5))
                        .foregroundColor(AmpColor.textDim)
                    Text("44k")
                        .font(.ampMono(6, weight: .bold))
                        .foregroundColor(AmpColor.amber)
                }
                .frame(width: 30, height: 28)
                .background(AmpColor.displayBg)
            }
            .padding(.trailing, 2)
            .padding(.vertical, 3)
        }
        .frame(width: AmpChrome.windowWidth, height: 34, alignment: .leading)
        .background(AmpColor.panelDark)
        .overlay(Rectangle().fill(AmpColor.bevelShadow).frame(height: 1), alignment: .bottom)
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
    }

    // ─── Seek + Time ─────────────────────────────────────────────────────────

    private var seekAndTime: some View {
        let shownPosition = seekPreviewSeconds ?? live.position
        return HStack(spacing: 2) {
            // Current time — compact so the scrub bar uses the full middle
            LedDigitDisplay(text: formatTime(shownPosition), size: 10)
                .frame(width: 32, alignment: .trailing)

            // Progress track — grows with row width (fills space between clocks)
            BevelBox(style: .inset) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track BG
                        AmpColor.trackBg

                        // Filled portion
                        let progress: CGFloat = {
                            guard let dur = live.duration, dur > 0 else { return 0 }
                            return min(1, max(0, CGFloat(shownPosition / dur)))
                        }()

                        if progress > 0 {
                            LinearGradient(
                                colors: [AmpColor.neonGreenDim, AmpColor.neonGreen],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(width: geo.size.width * progress)
                        }

                        // Thumb knob
                        if let dur = live.duration, dur > 0 {
                            let thumbX = geo.size.width * progress - 4
                            ZStack {
                                Rectangle().fill(AmpColor.panelLight).frame(width: 8, height: 10)
                                    .overlay(
                                        ZStack {
                                            VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer() }
                                            HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer() }
                                            VStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
                                            HStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                                        }
                                    )
                                Rectangle().fill(AmpColor.neonGreenDim).frame(width: 2, height: 6)
                            }
                            .offset(x: max(0, min(thumbX, geo.size.width - 8)))
                        }
                    }
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onChanged { val in
                                isDragging = true
                                let w = geo.size.width
                                guard w > 1, let dur = live.duration, dur > 0 else { return }
                                let pos = Double(val.location.x / w) * dur
                                let clamped = max(0, min(pos, dur))
                                seekPreviewSeconds = clamped
                                viewModel.seek(to: clamped)
                            }
                            .onEnded { _ in
                                isDragging = false
                                seekPreviewSeconds = nil
                            }
                    )
                }
                .frame(height: 10)
            }
            .frame(maxWidth: .infinity)

            // Total time
            LedDigitDisplay(text: formatTime(live.duration ?? 0), size: 10)
                .frame(width: 32, alignment: .leading)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
        .frame(width: AmpChrome.windowWidth, height: 20, alignment: .leading)
        .background(AmpColor.panelDark)
        .overlay(Rectangle().fill(AmpColor.bevelShadow).frame(height: 1), alignment: .bottom)
    }

    // ─── Transport Controls ───────────────────────────────────────────────────

    private var controlBar: some View {
        HStack(spacing: 2) {
            AmpButton(icon: "backward.end.fill",  width: 22, height: 18) { viewModel.playPrevious() }
            AmpButton(icon: "backward.fill",       width: 22, height: 18) { viewModel.playPrevious() }

            // Play/Pause — slightly larger, amber accent when playing
            Button(action: {
                if viewModel.state == .playing {
                    viewModel.pause()
                } else {
                    if viewModel.currentFile == nil { showingFilePicker = true } else { viewModel.play() }
                }
            }) {
                ZStack {
                    AmpColor.panelLight
                    Image(systemName: viewModel.state == .playing ? "pause.fill" : "play.fill")
                        .font(.ampMono(12, weight: .bold))
                        .foregroundColor(viewModel.state == .playing ? AmpColor.amber : AmpColor.neonGreen)
                        .shadow(color: (viewModel.state == .playing ? AmpColor.amber : AmpColor.neonGreen).opacity(0.8), radius: 4)
                }
                .frame(width: 28, height: 18)
                .overlay(
                    ZStack {
                        VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
                        HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                    }
                )
            }
            .buttonStyle(.plain)

            AmpButton(icon: "stop.fill",           width: 22, height: 18) { viewModel.stop() }
            AmpButton(icon: "forward.fill",        width: 22, height: 18) { viewModel.playNext() }
            AmpButton(icon: "forward.end.fill",    width: 22, height: 18) { viewModel.playNext() }

            Color.clear
                .frame(minHeight: 18)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .allowsWindowActivationEvents(true)

            // Volume knob area
            HStack(spacing: 3) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 7))
                    .foregroundColor(AmpColor.textDim)

                BevelBox(style: .inset) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            AmpColor.trackBg
                            LinearGradient(
                                colors: [AmpColor.neonGreenDim, AmpColor.neonGreen],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(width: geo.size.width * CGFloat(viewModel.volume))
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    viewModel.setVolume(max(0, min(1, Float(val.location.x / geo.size.width))))
                                }
                        )
                    }
                    .frame(width: 60, height: 7)
                }

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 7))
                    .foregroundColor(AmpColor.textDim)
            }
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 3)
        .frame(width: AmpChrome.windowWidth, height: 26, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AmpColor.panelMid, AmpColor.panelDark],
                startPoint: .top, endPoint: .bottom
            )
        )
        .overlay(Rectangle().fill(AmpColor.bevelShadow).frame(height: 1), alignment: .bottom)
    }

    // ─── Bottom Button Row ────────────────────────────────────────────────────

    private var bottomBar: some View {
        HStack(spacing: 2) {
            AmpButton(label: "LOAD", width: 32, height: 14) { showingFilePicker = true }
            AmpButton(label: "EQ",   isActive: showingEQ,     width: 24, height: 14) { showingEQ.toggle() }
            AmpButton(label: "LIST", isActive: showingPlaylist, width: 28, height: 14) { showingPlaylist.toggle() }
            AmpButton(label: "ART",  isActive: showingAlbumArt, width: 28, height: 14) { showingAlbumArt.toggle() }
            AmpButton(label: "SET",  width: 28, height: 14) { showingSettings.toggle() }
            AmpButton(label: "LYR",  width: 28, height: 14) { showingLyrics.toggle() }
            AmpButton(label: "SRCH", width: 28, height: 14) { showingSearch.toggle() }
            AmpButton(label: "PRO", isActive: showingPro, width: 26, height: 14) { showingPro.toggle() }

            Color.clear
                .frame(height: 14)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(WindowDragGesture())
                .allowsWindowActivationEvents(true)

            // Shuffle / Repeat LED indicators
            HStack(spacing: 3) {
                let shuffleOn = viewModel.playlist?.getShuffleMode() == .on
                let repeatOn  = viewModel.playlist?.getRepeatMode() == .all

                Text("S")
                    .font(.ampMono(7, weight: .bold))
                    .foregroundColor(shuffleOn ? AmpColor.neonGreen : AmpColor.textDim)
                    .shadow(color: shuffleOn ? AmpColor.neonGreen.opacity(0.9) : .clear, radius: 2)
                Text("R")
                    .font(.ampMono(7, weight: .bold))
                    .foregroundColor(repeatOn ? AmpColor.neonGreen : AmpColor.textDim)
                    .shadow(color: repeatOn ? AmpColor.neonGreen.opacity(0.9) : .clear, radius: 2)
            }
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 2)
        .frame(width: AmpChrome.windowWidth, height: 22, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AmpColor.panelDark, AmpColor.panelDeep],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    /// Five downsampled bands (0…1) for the mini spectrum; matches `AudioVisualizer` bin count.
    private var miniSpectrumBands: [Float] {
        let src = Array(live.spectrumData.prefix(20))
        guard src.count >= 20 else { return Array(repeating: 0, count: 5) }
        return (0..<5).map { k in
            let lo = k * 4
            let chunk = src[lo..<(lo + 4)]
            return chunk.reduce(0, +) / 4
        }
    }

    private var displayTitle: String {
        if let t = viewModel.metadata.title, !t.isEmpty { return t }
        if let f = viewModel.currentFile { return URL(fileURLWithPath: f).lastPathComponent }
        return "⚡ Drop a track here..."
    }

    private var displayArtist: String {
        viewModel.metadata.artist ?? "Unknown Artist"
    }

    private func formatTime(_ seconds: Double) -> String {
        let s = Int(seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    private func loadFileFromURL(_ url: URL) {
        let _ = url.startAccessingSecurityScopedResource()
        viewModel.loadFile(url: url)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { viewModel.play() }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for p in providers {
            if p.hasItemConformingToTypeIdentifier("public.file-url") {
                p.loadItem(forTypeIdentifier: "public.file-url") { item, _ in
                    let url: URL? = (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
                                 ?? (item as? URL)
                    if let url { DispatchQueue.main.async { self.loadFileFromURL(url) } }
                }
                return true
            }
        }
        return false
    }
}
