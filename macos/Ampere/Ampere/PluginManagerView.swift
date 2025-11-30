//
//  PluginManagerView.swift
//  Ampere
//
//  Plugin management and JavaScript automation interface
//

import SwiftUI
import UniformTypeIdentifiers

struct PluginManagerView: View {
    @ObservedObject var pluginManager: PluginManager
    @Environment(\.dismiss) private var dismiss
    @State private var scriptText = """
// Ampere JavaScript Automation Example
// Access player controls via Ampere object

// Play current track
Ampere.play();

// Set volume to 50%
Ampere.setVolume(0.5);

// Set EQ band 5 to +6dB
Ampere.setEQBand(5, 6.0);

// Add file to playlist
Ampere.addToPlaylist("/path/to/song.mp3");

// Log current position
console.log("Position: " + Ampere.getPosition());
"""
    @State private var showingScriptEditor = false
    @State private var scriptOutput = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Plugins & Automation")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { showingScriptEditor = true }) {
                    Text("SCRIPT")
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
            
            // Plugins list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LOADED PLUGINS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    
                    if pluginManager.plugins.isEmpty {
                        Text("No plugins loaded")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                            .padding(8)
                    } else {
                        ForEach(pluginManager.plugins, id: \.name) { plugin in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plugin.name)
                                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    Text("v\(plugin.version) by \(plugin.author)")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                            .cornerRadius(4)
                        }
                    }
                    
                    Text("JAVASCRIPT API")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        apiMethod("Ampere.play()", "Play current track")
                        apiMethod("Ampere.pause()", "Pause playback")
                        apiMethod("Ampere.stop()", "Stop playback")
                        apiMethod("Ampere.next()", "Play next track")
                        apiMethod("Ampere.previous()", "Play previous track")
                        apiMethod("Ampere.setVolume(value)", "Set volume (0.0-1.0)")
                        apiMethod("Ampere.getVolume()", "Get current volume")
                        apiMethod("Ampere.seek(position)", "Seek to position (seconds)")
                        apiMethod("Ampere.getPosition()", "Get current position")
                        apiMethod("Ampere.getDuration()", "Get track duration")
                        apiMethod("Ampere.loadFile(path)", "Load audio file")
                        apiMethod("Ampere.addToPlaylist(path)", "Add file to playlist")
                        apiMethod("Ampere.setEQBand(band, gain)", "Set EQ band gain (-12 to +12)")
                        apiMethod("console.log(message)", "Log message to console")
                    }
                    .padding(8)
                }
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        }
        .frame(width: 600, height: 700)
        .background(winampGradient)
        .cornerRadius(4)
        .sheet(isPresented: $showingScriptEditor) {
            ScriptEditorView(pluginManager: pluginManager, scriptText: $scriptText, output: $scriptOutput)
        }
    }
    
    private func apiMethod(_ method: String, _ description: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(method)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.0))
                .frame(width: 200, alignment: .leading)
            Text(description)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
        }
        .padding(.vertical, 2)
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

struct ScriptEditorView: View {
    @ObservedObject var pluginManager: PluginManager
    @Binding var scriptText: String
    @Binding var output: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("JavaScript Automation")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: runScript) {
                    Text("RUN")
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
            
            HStack(spacing: 0) {
                // Script editor
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCRIPT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    
                    TextEditor(text: $scriptText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .scrollContentBackground(.hidden)
                }
                .frame(width: 400)
                .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                
                Divider()
                
                // Output
                VStack(alignment: .leading, spacing: 4) {
                    Text("OUTPUT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    
                    ScrollView {
                        Text(output)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .background(Color(red: 0.12, green: 0.12, blue: 0.16))
                }
                .frame(width: 200)
                .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            }
        }
        .frame(width: 600, height: 500)
        .background(winampGradient)
        .cornerRadius(4)
    }
    
    private func runScript() {
        output = "Running script...\n"
        if let result = pluginManager.executeScript(scriptText) {
            output += "Result: \(result)\n"
        } else {
            output += "Script executed.\n"
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

