//
//  SettingsView.swift
//  Ampere
//
//  Settings and Theme panel
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isPresented: Bool
    @State private var showingEffects = false
    @State private var showingSpatialAudio = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Settings")
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
            
            TabView {
                // Themes Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        themeSection
                    }
                    .padding(8)
                }
                .tabItem {
                    Text("Themes")
                }
                
                // Audio Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        audioSection
                        channelSection
                        effectsSection
                        spatialAudioSection
                    }
                    .padding(8)
                }
                .tabItem {
                    Text("Audio")
                }
                
                // Plugins Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        pluginsSection
                    }
                    .padding(8)
                }
                .tabItem {
                    Text("Plugins")
                }
                
                // Display Tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        displaySection
                    }
                    .padding(8)
                }
                .tabItem {
                    Text("Display")
                }
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        }
        .frame(width: 320, height: 500)
        .background(winampGradient)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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
    
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THEME")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Button(action: {
                    themeManager.setTheme(theme)
                }) {
                    HStack {
                        Text(theme.rawValue)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        if themeManager.currentTheme == theme {
                            Text("✓")
                                .font(.system(size: 9))
                                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.0))
                        }
                    }
                    .padding(4)
                    .background(themeManager.currentTheme == theme ? Color(red: 0.2, green: 0.3, blue: 0.2) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AUDIO")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            HStack {
                Text("Volume:")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(viewModel.volume * 100))%")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Slider(value: Binding(
                get: { Double(viewModel.volume) },
                set: { viewModel.setVolume(Float($0)) }
            ), in: 0...1)
            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
        }
    }
    
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("EFFECTS")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Button(action: { showingEffects = true }) {
                HStack {
                    Text("Audio Effects")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
                .padding(4)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                .cornerRadius(2)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingEffects) {
                EffectsPanelView()
                    .frame(width: 400, height: 500)
            }
        }
    }
    
    private var spatialAudioSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("3D SOUND")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Button(action: { showingSpatialAudio = true }) {
                HStack {
                    Text("3D Sound Settings")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
                .padding(4)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                .cornerRadius(2)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingSpatialAudio) {
                SpatialAudioPanelView()
                    .frame(width: 400, height: 500)
            }
        }
    }
    
    private var channelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHANNELS")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Picker("Mode", selection: Binding(
                get: { viewModel.channelSettings.channelMode },
                set: { viewModel.channelSettings.channelMode = $0 }
            )) {
                ForEach(ChannelMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
            
            HStack {
                Text("Balance:")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "%.1f", viewModel.channelSettings.balance))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            Slider(value: Binding(
                get: { Double(viewModel.channelSettings.balance) },
                set: { viewModel.channelSettings.balance = Float($0) }
            ), in: -1...1)
            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
        }
    }
    
    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DISPLAY")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Toggle("Show Spectrum Analyzer", isOn: .constant(true))
                .toggleStyle(.switch)
                .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
            
            Toggle("Show Album Art", isOn: .constant(true))
                .toggleStyle(.switch)
                .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
        }
    }
    
    private var pluginsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PLUGINS & AUTOMATION")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Button(action: { showingPlugins = true }) {
                HStack {
                    Text("Plugin Manager")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                }
                .padding(4)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                .cornerRadius(2)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingPlugins) {
                PluginManagerView(pluginManager: viewModel.pluginManager)
            }
        }
    }
    
    @State private var showingPlugins = false
}

struct EffectsPanelView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @StateObject private var effects = AudioEffects()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Audio Effects")
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                // Reverb
                effectGroup(title: "REVERB", enabled: $effects.reverbEnabled) {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Wet/Dry Mix:")
                            Spacer()
                            Text("\(Int(effects.reverbWetDryMix))%")
                        }
                        Slider(value: $effects.reverbWetDryMix, in: 0...100)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                    }
                }
                
                // Delay
                effectGroup(title: "DELAY", enabled: $effects.delayEnabled) {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Time:")
                            Spacer()
                            Text("\(String(format: "%.2f", effects.delayTime))s")
                        }
                        Slider(value: $effects.delayTime, in: 0...2.0)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                        
                        HStack {
                            Text("Feedback:")
                            Spacer()
                            Text("\(Int(effects.delayFeedback))%")
                        }
                        Slider(value: $effects.delayFeedback, in: -100...100)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                    }
                }
                
                // Chorus
                effectGroup(title: "CHORUS", enabled: $effects.chorusEnabled) {
                    VStack(spacing: 6) {
                        HStack {
                            Text("Depth:")
                            Spacer()
                            Text("\(Int(effects.chorusDepth))%")
                        }
                        Slider(value: $effects.chorusDepth, in: 0...100)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                        
                        HStack {
                            Text("Rate:")
                            Spacer()
                            Text("\(String(format: "%.1f", effects.chorusRate)) Hz")
                        }
                        Slider(value: $effects.chorusRate, in: 0.1...20.0)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                    }
                }
                    // Distortion
                    effectGroup(title: "DISTORTION", enabled: $effects.distortionEnabled) {
                        VStack(spacing: 6) {
                            HStack {
                                Text("Pre-Gain:")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(String(format: "%.1f", effects.distortionPreGain)) dB")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.white)
                            }
                            Slider(value: $effects.distortionPreGain, in: -6...6)
                                .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                        }
                    }
                }
                .padding(8)
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        }
        .frame(width: 500, height: 600)
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
    
    private func effectGroup<Content: View>(title: String, enabled: Binding<Bool>, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: enabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
            }
            if enabled.wrappedValue {
                content()
            }
        }
        .padding(8)
        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
        .cornerRadius(4)
    }
}

struct SpatialAudioPanelView: View {
    @StateObject private var spatialAudio = SpatialAudio3D()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("3D SPATIAL AUDIO")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Toggle("", isOn: $spatialAudio.enabled)
                        .toggleStyle(.switch)
                        .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                }
                
                if spatialAudio.enabled {
                    VStack(spacing: 8) {
                        // Azimuth
                        HStack {
                            Text("Azimuth:")
                            Spacer()
                            Text("\(Int(spatialAudio.azimuth))°")
                        }
                        Slider(value: $spatialAudio.azimuth, in: -180...180)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                        
                        // Elevation
                        HStack {
                            Text("Elevation:")
                            Spacer()
                            Text("\(Int(spatialAudio.elevation))°")
                        }
                        Slider(value: $spatialAudio.elevation, in: -90...90)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                        
                        // Distance
                        HStack {
                            Text("Distance:")
                            Spacer()
                            Text("\(String(format: "%.2f", spatialAudio.distance))")
                        }
                        Slider(value: $spatialAudio.distance, in: 0.0...1.0)
                            .tint(Color(red: 0.0, green: 1.0, blue: 0.0))
                        
                        // Surround Mode
                        Picker("Surround Mode", selection: $spatialAudio.surroundMode) {
                            ForEach(SpatialAudio3D.SurroundMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white)
                }
            }
            .padding(8)
        }
        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
    }
}

