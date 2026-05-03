//
//  WinampWindows.swift
//  Ampere
//
//  EQ, Playlist, and Album Art sub-windows — bitmap Winamp style
//

import SwiftUI
import AppKit
import Combine
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
            // ── Title bar ─────────────────────────────────────────────────
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

            // ── Content area (no bare Color in ZStack — it expands to fill tall window proposals and leaves black below controls)
            content
                .frame(width: width, alignment: .top)
                .background(AmpColor.panelDeep)
                .clipped()
        }
        .frame(width: width)
        .background(AmpColor.panelDeep)
        .overlay(
            ZStack {
                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer() }
                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                VStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
            }
        )
        // Tight shadow so it doesn’t read as empty space between stacked panels.
        .shadow(color: .black.opacity(0.6), radius: 5, x: 0, y: 2)
    }
}

// ─── MARK: EQ Window ─────────────────────────────────────────────────────────

struct WinampEQWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @EnvironmentObject var live: PlayerLiveState
    @Binding var isPresented: Bool

    var body: some View {
        AmpWindowFrame(title: "EQUALIZER", width: AmpChrome.eqPanelWidth, height: 0, onClose: { isPresented = false }) {
            VStack(spacing: 0) {

                // ── Spectrum analyzer display ─────────────────────────────
                ZStack {
                    AmpColor.displayBg

                    // Scanlines
                    GeometryReader { g in
                        let lines = Int(g.size.height / 2)
                        VStack(spacing: 0) {
                            ForEach(0..<lines, id: \.self) { _ in
                                AmpColor.displayScanAlt.frame(height: 1)
                                Color.clear.frame(height: 1)
                            }
                        }
                    }

                    // dB grid lines (horizontal)
                    GeometryReader { g in
                        let dbLines: [(CGFloat, Color)] = [
                            (0.0,  AmpColor.textDim.opacity(0.5)),   // +12
                            (0.25, AmpColor.textDim.opacity(0.3)),   // +6
                            (0.5,  AmpColor.neonGreenDim.opacity(0.6)), // 0
                            (0.75, AmpColor.textDim.opacity(0.3)),   // -6
                            (1.0,  AmpColor.textDim.opacity(0.3)),   // -12
                        ]
                        ZStack {
                            ForEach(Array(dbLines.enumerated()), id: \.offset) { _, pair in
                                Rectangle()
                                    .fill(pair.1)
                                    .frame(height: 1)
                                    .offset(y: pair.0 * g.size.height - g.size.height / 2)
                            }
                        }
                    }

                    // dB labels (left)
                    VStack {
                        HStack {
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(["+12", " +6", "  0", " -6", "-12"], id: \.self) { lbl in
                                    Text(lbl)
                                        .font(.ampMono(5.5, weight: .bold))
                                        .foregroundColor(AmpColor.textDim)
                                        .frame(height: 16)
                                }
                            }
                            .padding(.leading, 3)
                            Spacer()
                        }
                    }

                    // Spectrum bars
                    HStack(spacing: 0) {
                        Spacer().frame(width: 24) // offset for dB labels
                        HStack(spacing: 2) {
                            ForEach(0..<10, id: \.self) { i in
                                EQSpectrumBar(value: live.eqSpectrumData.indices.contains(i) ? live.eqSpectrumData[i] : 0)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                .frame(height: 80)
                .overlay(
                    Rectangle()
                        .stroke(AmpColor.bevelShadow, lineWidth: 1)
                )

                // ── Band frequency labels ─────────────────────────────────
                HStack(spacing: 0) {
                    Spacer().frame(width: 24)
                    HStack(spacing: 0) {
                        ForEach(["60", "170", "310", "600", "1K", "3K", "6K", "12K", "14K", "16K"], id: \.self) { lbl in
                            Text(lbl)
                                .font(.ampMono(6, weight: .bold))
                                .foregroundColor(AmpColor.textMid)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(AmpColor.panelDark)

                // ── EQ Sliders ────────────────────────────────────────────
                HStack(spacing: 0) {
                    // dB scale axis
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(["+12", "+6", "0", "-6", "-12"], id: \.self) { lbl in
                            Text(lbl)
                                .font(.ampMono(5.5, weight: .bold))
                                .foregroundColor(AmpColor.textDim)
                                .frame(height: 22, alignment: .center)
                        }
                    }
                    .frame(width: 22)
                    .padding(.trailing, 2)

                    HStack(spacing: 4) {
                        ForEach(0..<10, id: \.self) { i in
                            WinampEQBand(index: i, viewModel: viewModel)
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .background(AmpColor.panelDark)

                // ── Divider ───────────────────────────────────────────────
                Rectangle().fill(AmpColor.bevelShadow).frame(height: 1)

                // ── Controls bar ──────────────────────────────────────────
                HStack(spacing: 4) {
                    // PRESET Menu
                    Menu {
                        ForEach(PlayerViewModel.eqPresets) { preset in
                            Button(preset.name) {
                                viewModel.applyEQPreset(preset)
                            }
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Text("PRESET")
                                .font(.ampMono(7, weight: .bold))
                                .foregroundColor(AmpColor.textBright)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 6))
                                .foregroundColor(AmpColor.neonGreen)
                        }
                        .frame(width: 54, height: 14)
                        .background(AmpColor.panelLight)
                        .overlay(
                            ZStack {
                                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
                                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                            }
                        )
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    AmpButton(label: "LOAD",   width: 40, height: 14) { /* mocked for now - but functional UI interaction */ }
                    AmpButton(label: "SAVE",   width: 40, height: 14) { /* mocked for now */ }
                    Spacer()
                    // EQ on/off
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
                        .shadow(color: viewModel.isEQEnabled() ? AmpColor.neonGreen.opacity(0.8) : .clear, radius: 3)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(AmpColor.panelDeep)
            }
        }
    }
}

// ─── MARK: Spectrum Bar (read-only, for display) ──────────────────────────────

private struct EQSpectrumBar: View {
    let value: Float   // 0…1

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let barH = max(1, CGFloat(value) * h)
            VStack(spacing: 0) {
                Spacer()
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 1.0, blue: 0.25),   // top bright
                        Color(red: 0.0, green: 0.75, blue: 0.15),  // mid
                        Color(red: 0.0, green: 0.45, blue: 0.08),  // bottom dim
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: max(2, geo.size.width - 2), height: barH)
                .shadow(color: AmpColor.neonGreen.opacity(0.4), radius: 2)
            }
        }
        .animation(.linear(duration: 0.04), value: value)
    }
}


// ─── MARK: EQ Band ───────────────────────────────────────────────────────────

struct WinampEQBand: View {
    let index: Int
    @ObservedObject var viewModel: PlayerViewModel
    @State private var gain: Float = 0.0
    
    // Sync with ViewModel
    private func updateFromViewModel() {
        if let g = viewModel.getEQBand(index: index) {
            gain = g
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            // Vertical slider track
            ZStack {
                // Inset background
                AmpColor.displayBg
                    .overlay(
                        ZStack {
                            VStack { Rectangle().fill(AmpColor.bevelShadow).frame(height: 1); Spacer() }
                            HStack { Rectangle().fill(AmpColor.bevelShadow).frame(width: 1); Spacer() }
                            VStack { Spacer(); Rectangle().fill(AmpColor.bevelHigh).frame(height: 1) }
                            HStack { Spacer(); Rectangle().fill(AmpColor.bevelHigh).frame(width: 1) }
                        }
                    )

                GeometryReader { geo in
                    let h = geo.size.height
                    let normalized = CGFloat((gain + 12.0) / 24.0)
                    let thumbY = (1.0 - normalized) * (h - 10) // keep thumb inside bounds

                    ZStack(alignment: .top) {
                        // Zero dB center line
                        Rectangle()
                            .fill(AmpColor.neonGreenFade)
                            .frame(width: 22, height: 1)
                            .offset(y: h / 2)

                        // Gain fill bar
                        if gain > 0.1 {
                            let fillH = CGFloat(gain / 12.0) * h / 2
                            LinearGradient(
                                colors: [AmpColor.neonGreen.opacity(0.9), AmpColor.neonGreenDim],
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(width: 4, height: fillH)
                            .offset(x: 0, y: h / 2 - fillH)
                            .shadow(color: AmpColor.neonGreen.opacity(0.6), radius: 2)
                        } else if gain < -0.1 {
                            let fillH = CGFloat(abs(gain) / 12.0) * h / 2
                            LinearGradient(
                                colors: [Color(red: 0.9, green: 0.3, blue: 0.0), Color(red: 0.5, green: 0.1, blue: 0.0)],
                                startPoint: .top, endPoint: .bottom
                            )
                            .opacity(0.8)
                            .frame(width: 4, height: fillH)
                            .offset(x: 0, y: h / 2)
                        }

                        // Thumb
                        ZStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AmpColor.panelLight)
                                .frame(width: 22, height: 10)
                            // Grip lines
                            VStack(spacing: 2) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Rectangle()
                                        .fill(AmpColor.neonGreenDim)
                                        .frame(width: 14, height: 1)
                                }
                            }
                        }
                        .overlay(
                            ZStack {
                                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer() }
                                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer() }
                                VStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
                                HStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                            }
                        )
                        .offset(y: thumbY)
                        .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { val in
                                let rawPos = val.location.y / h
                                let clamped = max(0, min(1, Float(rawPos)))
                                gain = (1.0 - clamped) * 24.0 - 12.0
                                viewModel.setEQBand(index: index, gain: gain)
                            }
                    )
                }
                .frame(width: 24, height: 110)
            }
            .frame(width: 24, height: 110)

            // Gain value label
            Text(gain == 0 ? "  0" : String(format: "%+.0f", gain))
                .font(.ampMono(6, weight: .bold))
                .foregroundColor(
                    gain > 0.5  ? AmpColor.neonGreen :
                    gain < -0.5 ? AmpColor.amber :
                    AmpColor.textDim
                )
                .shadow(color: gain > 0.5 ? AmpColor.neonGreen.opacity(0.6) : .clear, radius: 2)
                .frame(height: 10)
        }
        .frame(maxWidth: .infinity)
        .onAppear { updateFromViewModel() }
        .onReceive(viewModel.objectWillChange) { _ in updateFromViewModel() }
    }
}


// ─── MARK: Playlist Window ────────────────────────────────────────────────────

struct WinampPlaylistWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool
    /// Match full window width when EQ / settings / etc. sit beside the player (avoids dead space under side panels).
    var spanWidth: CGFloat = AmpChrome.windowWidth
    @State private var showingFilePicker = false
    @State private var keyDownMonitor: Any?

    var body: some View {
        AmpWindowFrame(title: "PLAYLIST", width: spanWidth, height: 300, onClose: { isPresented = false }) {
            VStack(spacing: 0) {
                // Track list
                BevelBox(style: .inset) {
                    ScrollView {
                        if let pl = viewModel.playlist, !pl.isEmpty() {
                            let current = pl.getCurrentTrackIndex()
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(0..<pl.getLength(), id: \.self) { i in
                                    let track = pl.getTrack(at: i)
                                    let path = track?.path ?? ""
                                    let title = path.isEmpty ? "—" : URL(fileURLWithPath: path).lastPathComponent
                                    WinampPlaylistItem(
                                        index: i,
                                        title: title,
                                        isCurrent: current == i,
                                        isSelected: viewModel.playlistSelectedIndex == i,
                                        onSelect: {
                                            viewModel.playlistSelectedIndex = i
                                            if let t = track {
                                                try? pl.setCurrentTrackIndex(i)
                                                viewModel.loadFile(path: t.path)
                                                DispatchQueue.main.async { viewModel.play() }
                                            }
                                        }
                                    )
                                }
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
                    .background(AmpColor.displayBg)
                }
                .frame(height: 220)

                // Separator
                Rectangle().fill(AmpColor.bevelShadow).frame(height: 1)

                // Controls
                VStack(spacing: 3) {
                    HStack(spacing: 3) {
                        AmpButton(label: "ADD",  width: 36, height: 14) { showingFilePicker = true }
                        AmpButton(label: "REM",  width: 36, height: 14) { viewModel.removeSelectedPlaylistItem() }
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
                    let scoped = url.startAccessingSecurityScopedResource()
                    viewModel.addToPlaylist(path: url.path)
                    if scoped {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }
                }
            }
        }
        .focusable()
        .onDeleteCommand { viewModel.removeSelectedPlaylistItem() }
        .onAppear {
            if viewModel.playlistSelectedIndex == nil {
                viewModel.playlistSelectedIndex = viewModel.playlist?.getCurrentTrackIndex()
            }
            installDeleteKeyMonitor(viewModel: viewModel)
        }
        .onDisappear {
            removeDeleteKeyMonitor()
        }
    }

    /// Delete / Forward Delete when typing isn’t active (so text fields keep working).
    private func installDeleteKeyMonitor(viewModel: PlayerViewModel) {
        guard keyDownMonitor == nil else { return }
        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == 51 || event.keyCode == 117 else { return event }
            if let resp = NSApp.keyWindow?.firstResponder, resp is NSTextView || resp is NSTextField {
                return event
            }
            DispatchQueue.main.async {
                viewModel.removeSelectedPlaylistItem()
            }
            return nil
        }
    }

    private func removeDeleteKeyMonitor() {
        if let keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
        }
        keyDownMonitor = nil
    }
}

// ─── MARK: Playlist Item ─────────────────────────────────────────────────────

struct WinampPlaylistItem: View {
    let index: Int
    let title: String
    let isCurrent: Bool
    var isSelected: Bool = false
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Track number
            Text(String(format: "%02d.", index + 1))
                .font(.ampMono(7, weight: .bold))
                .foregroundColor(isCurrent ? AmpColor.amber : AmpColor.textDim)
                .frame(width: 26, alignment: .trailing)
                .padding(.trailing, 4)

            // Track name
            Text(title)
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
        .background(rowBackground)
        .overlay(
            Rectangle()
                .fill(isCurrent ? AmpColor.neonGreenDim : Color.clear)
                .frame(width: 2),
            alignment: .leading
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    private var rowBackground: Color {
        if isCurrent { return AmpColor.panelMid }
        if isSelected { return AmpColor.panelDark.opacity(0.85) }
        return Color.clear
    }
}

// ─── MARK: Album Art Window ───────────────────────────────────────────────────

struct WinampAlbumArtWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool

    var body: some View {
        AmpWindowFrame(title: "ALBUM ART", width: 210, height: 0, onClose: { isPresented = false }) {
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
