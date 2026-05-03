//
//  ContentView.swift
//  Ampere
//
//  Main content view with Winamp-style windows.
//  Skin changes propagate through .applySkin() modifier.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @EnvironmentObject var themeManager: ThemeManager

    // Persist panel open/closed state across launches
    @AppStorage("showingEQ")       private var showingEQ       = false
    @AppStorage("showingPlaylist") private var showingPlaylist = false
    @AppStorage("showingAlbumArt") private var showingAlbumArt = false

    @State private var showingSettings = false
    @State private var showingLyrics   = false
    @State private var showingSearch   = false
    @State private var showingPro      = false

    /// Total horizontal chrome width (player + optional side panel). Keeps NSWindow matched so hidden title bar doesn’t leave empty side gutters.
    private var mainWindowRequiredWidth: CGFloat {
        let base = AmpChrome.windowWidth
        if showingEQ { return base + AmpChrome.eqPanelWidth }
        if showingAlbumArt { return base + AmpChrome.albumArtPanelWidth }
        if showingSettings { return base + AmpChrome.settingsPanelWidth }
        if showingSearch { return base + AmpChrome.searchPanelWidth }
        return base
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Top row: player + optional right panel ──────────────────────
            HStack(alignment: .top, spacing: 0) {
                WinampPlayerView(
                    showingEQ:       $showingEQ,
                    showingPlaylist: $showingPlaylist,
                    showingSettings: $showingSettings,
                    showingAlbumArt: $showingAlbumArt,
                    showingLyrics:   $showingLyrics,
                    showingSearch:   $showingSearch,
                    showingPro:      $showingPro
                )
                .environmentObject(viewModel)
                .layoutPriority(1)

                if showingEQ {
                    WinampEQWindow(isPresented: $showingEQ)
                        .environmentObject(viewModel)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if showingAlbumArt {
                    WinampAlbumArtWindow(isPresented: $showingAlbumArt)
                        .environmentObject(viewModel)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if showingSettings {
                    SettingsView(isPresented: $showingSettings)
                        .environmentObject(viewModel)
                        .environmentObject(themeManager)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if showingSearch {
                    SearchView(isPresented: $showingSearch)
                        .environmentObject(viewModel)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }

            // ── Bottom: playlist / lyrics panel ────────────────────────────
            if showingPlaylist {
                WinampPlaylistWindow(isPresented: $showingPlaylist, spanWidth: mainWindowRequiredWidth)
                    .environmentObject(viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showingLyrics {
                WinampLyricsWindow(isPresented: $showingLyrics, spanWidth: mainWindowRequiredWidth)
                    .environmentObject(viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showingPro {
                WinampProPanel(isPresented: $showingPro, spanWidth: mainWindowRequiredWidth)
                    .environmentObject(viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: mainWindowRequiredWidth, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .clipped()
        .ignoresSafeArea(.container, edges: [.horizontal, .top])
        // Apply skin to the entire tree so AmpColor._skin stays in sync
        .applySkin(themeManager)
        .animation(.easeInOut(duration: 0.18), value: showingEQ)
        .animation(.easeInOut(duration: 0.18), value: showingPlaylist)
        .animation(.easeInOut(duration: 0.18), value: showingAlbumArt)
        .animation(.easeInOut(duration: 0.18), value: showingSettings)
        .animation(.easeInOut(duration: 0.18), value: showingLyrics)
        .animation(.easeInOut(duration: 0.18), value: showingSearch)
        .animation(.easeInOut(duration: 0.18), value: showingPro)
        .animation(.easeInOut(duration: 0.25), value: themeManager.activeTheme)
        .borderlessWindow()
        .background(MainWindowWidthSync(requiredWidth: mainWindowRequiredWidth))
    }
}
