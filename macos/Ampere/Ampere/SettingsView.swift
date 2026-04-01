//
//  SettingsView.swift
//  Ampere
//
//  Settings panel — Winamp bitmap style, matching AmpWindowFrame aesthetic.
//  Theme selector with colour swatches + custom skin support.
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool

    @State private var selectedTab: SettingsTab = .themes
    @State private var showingEffects      = false
    @State private var showingSpatial      = false
    @State private var showingPlugins      = false
    @State private var showingAnalytics    = false

    enum SettingsTab: String, CaseIterable {
        case themes  = "SKINS"
        case audio   = "AUDIO"
        case display = "DISPLAY"
        case plugins = "PLUGINS"
    }

    // Matches EQ width for visual coherence when shown side-by-side
    private let panelWidth: CGFloat = 320

    var body: some View {
        VStack(spacing: 0) {

            // ── Title bar ─────────────────────────────────────────────────
            HStack(spacing: 4) {
                Text("⚡").font(.system(size: 8, weight: .black)).foregroundColor(AmpColor.amber)
                Text("SETTINGS")
                    .font(.ampMono(8, weight: .bold))
                    .foregroundColor(AmpColor.neonGreen)
                    .kerning(1)
                    .shadow(color: AmpColor.neonGreen.opacity(0.5), radius: 2)
                Spacer()
                Button(action: { isPresented = false }) {
                    ZStack {
                        AmpColor.panelLight
                        Text("✕").font(.ampMono(7, weight: .bold)).foregroundColor(AmpColor.textBright)
                    }
                    .frame(width: 12, height: 12)
                    .overlay(ZStack {
                        VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height:1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height:1) }
                        HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width:1);  Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width:1) }
                    })
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .frame(height: 16)
            .background(LinearGradient(colors: [AmpColor.panelMid, AmpColor.panelDeep], startPoint: .top, endPoint: .bottom))
            .overlay(Rectangle().fill(AmpColor.bevelShadow).frame(height: 1), alignment: .bottom)

            // ── Tab strip ─────────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    let active = selectedTab == tab
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.ampMono(7, weight: .bold))
                            .foregroundColor(active ? AmpColor.neonGreen : AmpColor.textDim)
                            .shadow(color: active ? AmpColor.neonGreen.opacity(0.7) : .clear, radius: 2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(active ? AmpColor.panelDark : AmpColor.panelDeep)
                            .overlay(Rectangle().fill(active ? AmpColor.neonGreenFade : Color.clear).frame(height: 1), alignment: .bottom)
                    }
                    .buttonStyle(.plain)
                    Rectangle().fill(AmpColor.bevelShadow).frame(width: 1)
                }
                Spacer()
            }
            .background(AmpColor.panelDeep)
            .overlay(Rectangle().fill(AmpColor.bevelShadow).frame(height: 1), alignment: .bottom)

            // ── Content area ──────────────────────────────────────────────
            ScrollView(.vertical, showsIndicators: false) {
                Group {
                    switch selectedTab {
                    case .themes:  themesContent
                    case .audio:   audioContent
                    case .display: displayContent
                    case .plugins: pluginsContent
                    }
                }
                .padding(8)
            }
            .background(AmpColor.panelDark)
        }
        .frame(width: panelWidth, height: 300)
        .background(AmpColor.panelDeep)
        .clipped()
        .overlay(
            ZStack {
                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height: 1); Spacer() }
                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width: 1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width: 1) }
                VStack { Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height: 1) }
            }
        )
        .shadow(color: .black.opacity(0.75), radius: 12, x: 3, y: 5)
        // Sheets for sub-panels
        .sheet(isPresented: $showingEffects) {
            EffectsPanelView()
                .environmentObject(viewModel)
                .frame(width: 400, height: 520)
        }
        .sheet(isPresented: $showingSpatial) {
            SpatialAudioPanelView()
                .frame(width: 400, height: 480)
        }
        .sheet(isPresented: $showingPlugins) {
            PluginManagerView(pluginManager: viewModel.pluginManager)
        }
        .sheet(isPresented: $showingAnalytics) {
            AnalyticsView()
                .environmentObject(viewModel)
        }
    }

    // ─── Themes Tab ───────────────────────────────────────────────────────────

    private var themesContent: some View {
        VStack(alignment: .leading, spacing: 10) {

            sectionHeader("BUILT-IN SKINS")

            // 2-column grid of skin tiles
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(BuiltInTheme.allCases) { theme in
                    SkinTile(
                        theme: theme,
                        isActive: themeManager.activeTheme == theme && themeManager.activeCustomSkinId == nil,
                        onSelect: { themeManager.setTheme(theme) }
                    )
                }
            }

            // ── Custom skins
            if !themeManager.customSkins.isEmpty {
                sectionHeader("CUSTOM SKINS")
                    .padding(.top, 4)

                VStack(spacing: 3) {
                    ForEach(themeManager.customSkins) { skin in
                        CustomSkinRow(
                            skin: skin,
                            isActive: themeManager.activeCustomSkinId == skin.id,
                            onSelect: { themeManager.activateCustomSkin(skin) }
                        )
                    }
                }
            }

            // ── Skin folder hint
            sectionHeader("SKIN FOLDER")
                .padding(.top, 4)
            VStack(alignment: .leading, spacing: 3) {
                Text("Drop skin folders into:")
                    .font(.ampMono(7))
                    .foregroundColor(AmpColor.textDim)
                Button(action: openSkinsFolder) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 9))
                            .foregroundColor(AmpColor.amber)
                        Text("~/Library/Application Support/Ampere/Skins/")
                            .font(.ampMono(6.5))
                            .foregroundColor(AmpColor.neonGreenDim)
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding(5)
                    .background(AmpColor.displayBg)
                    .overlay(Rectangle().stroke(AmpColor.bevelShadow, lineWidth: 1))
                }
                .buttonStyle(.plain)
                Button(action: { themeManager.scanCustomSkins() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.clockwise").font(.system(size: 8))
                        Text("RESCAN")
                    }
                    .font(.ampMono(7, weight: .bold))
                    .foregroundColor(AmpColor.textBright)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AmpColor.panelLight)
                    .overlay(ZStack {
                        VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height:1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height:1) }
                        HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width:1);  Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width:1) }
                    })
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func openSkinsFolder() {
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = support.appendingPathComponent("Ampere/Skins")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            NSWorkspace.shared.open(dir)
        }
    }

    // ─── Audio Tab ────────────────────────────────────────────────────────────

    private var audioContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("VOLUME")
            ampSlider(
                label: "\(Int(viewModel.volume * 100))%",
                value: Binding(get: { Double(viewModel.volume) },
                               set: { viewModel.setVolume(Float($0)) }),
                range: 0...1
            )

            Divider().background(AmpColor.bevelShadow)

            sectionHeader("CROSSFADE")
            ampToggle("Enable Crossfade",
                      isOn: Binding(get:  { viewModel.crossfadeManager.enabled },
                                    set: { viewModel.crossfadeManager.setEnabled($0) }))
            if viewModel.crossfadeManager.enabled {
                ampSlider(
                    label: String(format: "%.1fs", viewModel.crossfadeManager.duration),
                    value: Binding(get: { viewModel.crossfadeManager.duration },
                                   set: { viewModel.crossfadeManager.setDuration($0) }),
                    range: 0...10
                )
            }

            Divider().background(AmpColor.bevelShadow)

            sectionHeader("REPLAYGAIN")
            Picker("", selection: Binding(get:  { viewModel.replayGainProcessor.mode },
                                          set: { viewModel.replayGainProcessor.setMode($0) })) {
                Text("Off").tag(ReplayGainMode.off)
                Text("Track").tag(ReplayGainMode.track)
                Text("Album").tag(ReplayGainMode.album)
                Text("Auto").tag(ReplayGainMode.auto)
            }
            .pickerStyle(.menu)
            .controlSize(.small)
            .tint(AmpColor.neonGreen)

            Divider().background(AmpColor.bevelShadow)

            sectionHeader("CHANNELS")
            Picker("", selection: Binding(get:  { viewModel.channelSettings.channelMode },
                                          set: { viewModel.channelSettings.channelMode = $0 })) {
                ForEach(ChannelMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.menu)
            .controlSize(.small)
            .tint(AmpColor.neonGreen)

            ampSlider(
                label: String(format: "BAL %.1f", viewModel.channelSettings.balance),
                value: Binding(get: { Double(viewModel.channelSettings.balance) },
                               set: { viewModel.channelSettings.balance = Float($0) }),
                range: -1...1
            )

            Divider().background(AmpColor.bevelShadow)

            sectionHeader("EFFECTS")
            ampNavRow(label: "Audio Effects")  { showingEffects = true }
            ampNavRow(label: "3D Spatial Audio") { showingSpatial = true }
        }
    }

    // ─── Display Tab ──────────────────────────────────────────────────────────

    private var displayContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("DISPLAY OPTIONS")
            ampToggle("Show Spectrum Analyzer", isOn: .constant(true))
            ampToggle("Show Album Art",          isOn: .constant(true))
            ampToggle("Marquee Scroll Title",     isOn: .constant(true))
        }
    }

    // ─── Plugins Tab ──────────────────────────────────────────────────────────

    private var pluginsContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("PLUGINS & AUTOMATION")
            ampNavRow(label: "Plugin Manager")   { showingPlugins = true }
            sectionHeader("ANALYTICS")
                .padding(.top, 4)
            ampNavRow(label: "Listening Stats")  { showingAnalytics = true }
        }
    }

    // ─── Reusable components ──────────────────────────────────────────────────

    private func sectionHeader(_ text: String) -> some View {
        HStack(spacing: 4) {
            Rectangle().fill(AmpColor.neonGreenDim).frame(width: 2, height: 10)
            Text(text)
                .font(.ampMono(7, weight: .bold))
                .foregroundColor(AmpColor.textMid)
                .kerning(0.8)
            Spacer()
        }
    }

    private func ampSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 2) {
            HStack {
                Spacer()
                Text(label)
                    .font(.ampMono(7, weight: .bold))
                    .foregroundColor(AmpColor.neonGreen)
                    .shadow(color: AmpColor.neonGreen.opacity(0.5), radius: 1)
            }
            Slider(value: value, in: range)
                .tint(AmpColor.neonGreen)
                .controlSize(.small)
        }
    }

    private func ampToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.ampMono(8))
                .foregroundColor(AmpColor.textBright)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .tint(AmpColor.neonGreen)
        }
    }

    private func ampNavRow(label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.ampMono(8))
                    .foregroundColor(AmpColor.textBright)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 8))
                    .foregroundColor(AmpColor.neonGreenDim)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(AmpColor.panelMid)
            .overlay(ZStack {
                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height:1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height:1) }
                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width:1);  Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width:1) }
            })
        }
        .buttonStyle(.plain)
    }
}

// ─── MARK: Skin Tile ──────────────────────────────────────────────────────────

private struct SkinTile: View {
    let theme: BuiltInTheme
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 4) {
                // Mini player preview
                ZStack {
                    theme.colors.panelDeep
                    VStack(spacing: 2) {
                        // Fake title bar
                        HStack(spacing: 2) {
                            Circle().fill(theme.colors.amber).frame(width: 3, height: 3)
                            Rectangle().fill(theme.colors.neonGreen.opacity(0.6)).frame(height: 1)
                        }
                        .padding(.horizontal, 4)
                        // Fake LCD
                        Rectangle().fill(theme.colors.displayBg)
                            .frame(height: 8)
                            .padding(.horizontal, 4)
                            .overlay(
                                HStack(spacing: 1) {
                                    ForEach(0..<8, id: \.self) { i in
                                        Rectangle()
                                            .fill(theme.colors.neonGreen.opacity(Double(8 - i) / 8.0))
                                            .frame(width: 2, height: 4)
                                    }
                                }
                                .padding(.horizontal, 6)
                            )
                        // Fake controls
                        HStack(spacing: 2) {
                            ForEach(0..<4, id: \.self) { _ in
                                Rectangle()
                                    .fill(theme.colors.panelLight)
                                    .frame(width: 8, height: 5)
                                    .overlay(Rectangle().stroke(theme.colors.bevelShadow, lineWidth: 0.5))
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .stroke(isActive ? theme.colors.neonGreen : theme.colors.bevelShadow, lineWidth: isActive ? 1.5 : 0.5)
                )
                .shadow(color: isActive ? theme.colors.neonGreen.opacity(0.4) : .clear, radius: 3)

                // Label
                Text(theme.rawValue)
                    .font(.ampMono(6.5, weight: isActive ? .bold : .regular))
                    .foregroundColor(isActive ? AmpColor.neonGreen : AmpColor.textMid)
                    .shadow(color: isActive ? AmpColor.neonGreen.opacity(0.6) : .clear, radius: 2)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }
}

// ─── MARK: Custom Skin Row ────────────────────────────────────────────────────

private struct CustomSkinRow: View {
    let skin: CustomSkin
    let isActive: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                // Thumbnail
                if let thumb = skin.thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 28)
                        .clipped()
                } else {
                    ZStack {
                        AmpColor.displayBg
                        Image(systemName: "photo").font(.system(size: 10)).foregroundColor(AmpColor.textDim)
                    }
                    .frame(width: 40, height: 28)
                }

                Text(skin.name)
                    .font(.ampMono(8))
                    .foregroundColor(isActive ? AmpColor.neonGreen : AmpColor.textBright)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if isActive {
                    Text("✓")
                        .font(.ampMono(9, weight: .bold))
                        .foregroundColor(AmpColor.neonGreen)
                        .shadow(color: AmpColor.neonGreen.opacity(0.8), radius: 2)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isActive ? AmpColor.panelMid : AmpColor.panelDark)
            .overlay(ZStack {
                VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height:1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height:1) }
                HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width:1);  Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width:1) }
            })
        }
        .buttonStyle(.plain)
    }
}

// ─── MARK: Effects & Spatial sub-views (kept from original) ───────────────────

struct EffectsPanelView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @StateObject private var effects = AudioEffects()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("⚡  AUDIO EFFECTS")
                    .font(.ampMono(9, weight: .bold))
                    .foregroundColor(AmpColor.neonGreen)
                    .shadow(color: AmpColor.neonGreen.opacity(0.5), radius: 2)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").font(.system(size: 9)).foregroundColor(AmpColor.textBright)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(LinearGradient(colors: [AmpColor.panelMid, AmpColor.panelDeep], startPoint: .top, endPoint: .bottom))

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    effectGroup(title: "REVERB", enabled: $effects.reverbEnabled) {
                        labeledSlider("Wet/Dry:", value: $effects.reverbWetDryMix, range: (0 as Float)...(100 as Float),
                                      fmt: { "\(Int($0))%" })
                    }
                    effectGroup(title: "DELAY", enabled: $effects.delayEnabled) {
                        VStack(spacing: 4) {
                            labeledSlider("Time:",     value: $effects.delayTime,     range: (0 as Float)...(2 as Float),    fmt: { String(format: "%.2fs", $0) })
                            labeledSlider("Feedback:", value: $effects.delayFeedback, range: (-100 as Float)...(100 as Float), fmt: { "\(Int($0))%" })
                        }
                    }
                    effectGroup(title: "CHORUS", enabled: $effects.chorusEnabled) {
                        VStack(spacing: 4) {
                            labeledSlider("Depth:", value: $effects.chorusDepth, range: (0 as Float)...(100 as Float), fmt: { "\(Int($0))%" })
                            labeledSlider("Rate:",  value: $effects.chorusRate,  range: (0.1 as Float)...(20 as Float), fmt: { String(format: "%.1f Hz", $0) })
                        }
                    }
                    effectGroup(title: "DISTORTION", enabled: $effects.distortionEnabled) {
                        labeledSlider("Pre-Gain:", value: $effects.distortionPreGain, range: (-6 as Float)...(6 as Float), fmt: { String(format: "%.1f dB", $0) })
                    }
                }
                .padding(8)
            }
            .background(AmpColor.panelDark)
        }
        .background(AmpColor.panelDeep)
    }

    private func effectGroup<C: View>(title: String, enabled: Binding<Bool>, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.ampMono(8, weight: .bold)).foregroundColor(AmpColor.textBright)
                Spacer()
                Toggle("", isOn: enabled).toggleStyle(.switch).controlSize(.mini).tint(AmpColor.neonGreen)
            }
            if enabled.wrappedValue { content() }
        }
        .padding(8)
        .background(AmpColor.panelMid)
        .overlay(ZStack {
            VStack { Rectangle().fill(AmpColor.bevelHigh).frame(height:1); Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(height:1) }
            HStack { Rectangle().fill(AmpColor.bevelHigh).frame(width:1);  Spacer(); Rectangle().fill(AmpColor.bevelShadow).frame(width:1) }
        })
    }

    private func labeledSlider(_ label: String, value: Binding<Float>, range: ClosedRange<Float>, fmt: (Float) -> String) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label).font(.ampMono(7)).foregroundColor(AmpColor.textMid)
                Spacer()
                Text(fmt(value.wrappedValue)).font(.ampMono(7, weight: .bold)).foregroundColor(AmpColor.neonGreen)
            }
            Slider(value: value, in: range).tint(AmpColor.neonGreen).controlSize(.small)
        }
    }
}

struct SpatialAudioPanelView: View {
    @StateObject private var spatialAudio = SpatialAudio3D()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("⚡  3D SPATIAL AUDIO")
                    .font(.ampMono(9, weight: .bold))
                    .foregroundColor(AmpColor.neonGreen)
                    .shadow(color: AmpColor.neonGreen.opacity(0.5), radius: 2)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").font(.system(size: 9)).foregroundColor(AmpColor.textBright)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(LinearGradient(colors: [AmpColor.panelMid, AmpColor.panelDeep], startPoint: .top, endPoint: .bottom))

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ENABLE 3D SOUND").font(.ampMono(8, weight: .bold)).foregroundColor(AmpColor.textBright)
                        Spacer()
                        Toggle("", isOn: $spatialAudio.enabled).toggleStyle(.switch).controlSize(.mini).tint(AmpColor.neonGreen)
                    }
                    if spatialAudio.enabled {
                        Group {
                            sliderRow("Azimuth",   value: $spatialAudio.azimuth,   range: (-180 as Float)...(180 as Float), unit: "°")
                            sliderRow("Elevation", value: $spatialAudio.elevation, range: (-90 as Float)...(90 as Float),   unit: "°")
                            sliderRow("Distance",  value: $spatialAudio.distance,  range: (0 as Float)...(1 as Float),      unit: "")
                        }
                        Picker("Surround Mode", selection: $spatialAudio.surroundMode) {
                            ForEach(SpatialAudio3D.SurroundMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(AmpColor.neonGreen)
                        .font(.ampMono(8))
                    }
                }
                .padding(8)
            }
            .background(AmpColor.panelDark)
        }
        .background(AmpColor.panelDeep)
    }

    private func sliderRow(_ label: String, value: Binding<Float>, range: ClosedRange<Float>, unit: String) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label).font(.ampMono(7)).foregroundColor(AmpColor.textMid)
                Spacer()
                Text(String(format: "%.0f\(unit)", value.wrappedValue))
                    .font(.ampMono(7, weight: .bold)).foregroundColor(AmpColor.neonGreen)
            }
            Slider(value: value, in: range).tint(AmpColor.neonGreen).controlSize(.small)
        }
    }
}
