//
//  AmpereApp.swift
//  Ampere
//
//  Professional Audio Player
//

import SwiftUI
import AppKit

@main
struct AmpereApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var menuBarManager = MenuBarManager()
    
    init() {
        // Set app appearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerViewModel)
                .environmentObject(themeManager)
                .onAppear {
                    setupWindow()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 275, height: 140)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Button("About Ampere") {
                    NSApp.orderFrontStandardAboutPanel()
                }
            }
        }
    }
    
    private func setupWindow() {
        DispatchQueue.main.async {
            // Find the main window (skip status bar windows)
            if let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) {
                window.title = "Ampere"
                window.isMovableByWindowBackground = true
                window.level = .floating
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            }
        }
    }
}

