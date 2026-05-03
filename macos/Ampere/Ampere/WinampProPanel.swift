//
//  WinampProPanel.swift
//  Ampere
//
//  Extended track info — Winamp-style recessed LCD / bevel panels (not a plain text list).
//

import SwiftUI

struct WinampProPanel: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool
    /// Align with playlist when side panels (EQ, etc.) are open.
    var spanWidth: CGFloat = AmpChrome.windowWidth

    @State private var scannedBPM: Double?
    @State private var isScanning = false

    private let scrollH: CGFloat = 244

    var body: some View {
        AmpWindowFrame(title: "PRO — TRACK INFO", width: spanWidth, height: 260, onClose: { isPresented = false }) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    tempoBlock

                    sectionDividerLabel("FILE METADATA")

                    retroRow(code: "TIT", label: "Title", value: viewModel.metadata.title)
                    retroRow(code: "ART", label: "Artist", value: viewModel.metadata.artist)
                    retroRow(code: "WRT", label: "Writer", value: viewModel.metadata.composer)
                    retroRow(code: "ALB", label: "Album", value: viewModel.metadata.album)
                    retroRow(code: "GEN", label: "Genre", value: viewModel.metadata.genre)
                    retroRow(code: "YR", label: "Year", value: viewModel.metadata.year.map(String.init))
                    retroRow(code: "TRK", label: "Track", value: viewModel.metadata.trackNumber.map(String.init))
                    if let d = viewModel.metadata.duration {
                        retroRow(code: "LEN", label: "Duration", value: formatDuration(d))
                    }

                    extraTagsSection
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: scrollH)
            .background(
                LinearGradient(
                    colors: [AmpColor.panelDark, AmpColor.panelDeep],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear { refreshBPMIfNeeded() }
        .onChange(of: viewModel.currentFile) { _, _ in
            scannedBPM = nil
            refreshBPMIfNeeded()
        }
    }

    // MARK: - Tempo / BPM (LCD-style block)

    private var tempoBlock: some View {
        BevelBox(style: .inset) {
            ZStack(alignment: .topLeading) {
                LcdBackground()
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TEMPO")
                            .font(.ampMono(6, weight: .bold))
                            .foregroundColor(AmpColor.textDim)
                            .tracking(2)

                        ZStack(alignment: .leading) {
                            LedDigitDisplay(text: bpmGhostMask, size: 15, color: AmpColor.neonGreenFade.opacity(0.35))
                            LedDigitDisplay(text: bpmLedText, size: 15, color: bpmLedColor)
                        }

                        Text(bpmSourceCaption)
                            .font(.ampMono(6.5, weight: .bold))
                            .foregroundColor(bpmSourceColor)
                            .tracking(1)
                    }

                    Spacer(minLength: 4)

                    VStack(alignment: .trailing, spacing: 6) {
                        if isScanning {
                            ProgressView()
                                .scaleEffect(0.7)
                                .padding(.top, 4)
                        }
                        AmpButton(label: "SCAN", width: 44, height: 14) {
                            scannedBPM = nil
                            runBPMScan()
                        }
                        .disabled(viewModel.currentFile == nil || isScanning)
                    }
                }
                .padding(10)
            }
            .frame(height: 72)
        }
    }

    private var bpmGhostMask: String {
        let s = bpmLedText
        return String(repeating: "8", count: max(5, s.count))
    }

    private var bpmLedText: String {
        if let t = viewModel.metadata.bpmFromTag {
            return String(format: "%05.1f", t)
        }
        if isScanning {
            return " SCAN"
        }
        if let e = scannedBPM {
            return String(format: "%05.1f", e)
        }
        return " --.--"
    }

    private var bpmLedColor: Color {
        if viewModel.metadata.bpmFromTag != nil { return AmpColor.neonGreen }
        if scannedBPM != nil { return AmpColor.amber }
        return AmpColor.neonGreenDim
    }

    private var bpmSourceCaption: String {
        if viewModel.metadata.bpmFromTag != nil { return "SOURCE · ID3 TAG" }
        if isScanning { return "ANALYZING PCM…" }
        if scannedBPM != nil { return "SOURCE · ESTIMATE" }
        return "NO TEMP · TAP SCAN"
    }

    private var bpmSourceColor: Color {
        if viewModel.metadata.bpmFromTag != nil { return AmpColor.neonGreen.opacity(0.85) }
        if scannedBPM != nil { return AmpColor.amber.opacity(0.9) }
        return AmpColor.textDim
    }

    // MARK: - Retro metadata rows

    private func sectionDividerLabel(_ title: String) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(AmpColor.bevelShadow)
                .frame(height: 1)
            Text(title)
                .font(.ampMono(6.5, weight: .bold))
                .foregroundColor(AmpColor.neonGreenFade)
                .shadow(color: AmpColor.neonGreen.opacity(0.35), radius: 2)
            Rectangle()
                .fill(AmpColor.bevelShadow)
                .frame(height: 1)
        }
        .padding(.top, 4)
    }

    private func retroRow(code: String, label: String, value: String?) -> some View {
        let display = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let show = display.isEmpty ? "—" : display

        return HStack(alignment: .center, spacing: 5) {
            // Raised-style code badge (Winamp strip label)
            ZStack {
                LinearGradient(
                    colors: [AmpColor.panelLight.opacity(0.9), AmpColor.panelMid],
                    startPoint: .top,
                    endPoint: .bottom
                )
                VStack(spacing: 0) {
                    Text(code)
                        .font(.ampMono(8, weight: .black))
                        .foregroundColor(AmpColor.textBright)
                    Text(label)
                        .font(.ampMono(5))
                        .foregroundColor(AmpColor.textDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(3)
            }
            .frame(width: 44, height: 36)
            .overlay(
                ZStack {
                    VStack {
                        Rectangle().fill(AmpColor.bevelHigh).frame(height: 1)
                        Spacer()
                        Rectangle().fill(AmpColor.bevelShadow).frame(height: 1)
                    }
                    HStack {
                        Rectangle().fill(AmpColor.bevelHigh).frame(width: 1)
                        Spacer()
                        Rectangle().fill(AmpColor.bevelShadow).frame(width: 1)
                    }
                }
            )

            BevelBox(style: .inset) {
                ZStack(alignment: .leading) {
                    LcdBackground()
                    Text(show)
                        .font(.ampMono(7.5))
                        .foregroundColor(AmpColor.neonGreen)
                        .shadow(color: AmpColor.neonGreen.opacity(0.45), radius: 1)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 36)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var extraTagsSection: some View {
        let extras = viewModel.metadata.customTags.filter { key, _ in
            !key.uppercased().contains("REPLAYGAIN")
        }
        return Group {
            if !extras.isEmpty {
                sectionDividerLabel("EXTRA TAGS")

                ForEach(extras.keys.sorted(), id: \.self) { key in
                    retroRow(
                        code: String(key.prefix(3)).uppercased(),
                        label: key,
                        value: extras[key]
                    )
                }
            }
        }
    }

    private func formatDuration(_ s: Double) -> String {
        let m = Int(s) / 60
        let sec = Int(s) % 60
        return String(format: "%d:%02d", m, sec)
    }

    private func refreshBPMIfNeeded() {
        guard viewModel.metadata.bpmFromTag == nil,
              viewModel.currentFile != nil else { return }
        runBPMScan()
    }

    private func runBPMScan() {
        guard let path = viewModel.currentFile else { return }
        let url = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: path) else { return }

        isScanning = true
        scannedBPM = nil
        BPMAnalyzer.estimateBPM(fileURL: url) { result in
            isScanning = false
            scannedBPM = result
        }
    }
}
