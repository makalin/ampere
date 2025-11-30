//
//  ContentView.swift
//  Ampere
//
//  Main content view with Winamp-style windows
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showingEQ = false
    @State private var showingPlaylist = false
    @State private var showingSettings = false
    @State private var showingAlbumArt = false
    @State private var showingLyrics = false
    @State private var showingSearch = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Main player window
            WinampPlayerView(showingEQ: $showingEQ, showingPlaylist: $showingPlaylist, showingSettings: $showingSettings, showingAlbumArt: $showingAlbumArt, showingLyrics: $showingLyrics, showingSearch: $showingSearch)
                .environmentObject(viewModel)
                .zIndex(1)
            
            // Additional windows - positioned relative to main window
            if showingEQ {
                WinampEQWindow(isPresented: $showingEQ)
                    .environmentObject(viewModel)
                    .offset(x: 280, y: 0)
                    .zIndex(2)
            }
            
            if showingPlaylist {
                WinampPlaylistWindow(isPresented: $showingPlaylist)
                    .environmentObject(viewModel)
                    .offset(x: 0, y: 116)
                    .zIndex(2)
            }
            
            if showingSettings {
                SettingsView(isPresented: $showingSettings)
                    .environmentObject(viewModel)
                    .environmentObject(themeManager)
                    .offset(x: 280, y: 0)
                    .zIndex(3)
            }
            
            if showingAlbumArt {
                WinampAlbumArtWindow(isPresented: $showingAlbumArt)
                    .environmentObject(viewModel)
                    .offset(x: 280, y: 116)
                    .zIndex(2)
            }
            
            if showingLyrics {
                WinampLyricsWindow(isPresented: $showingLyrics)
                    .environmentObject(viewModel)
                    .offset(x: 0, y: 416)
                    .zIndex(2)
            }
            
            if showingSearch {
                SearchView(isPresented: $showingSearch)
                    .environmentObject(viewModel)
                    .offset(x: 280, y: 0)
                    .zIndex(4)
            }
        }
        .frame(width: showingEQ || showingSettings ? 600 : 275, 
               height: showingPlaylist ? 416 : (showingSettings ? 500 : 116))
        .borderlessWindow()
    }
}
