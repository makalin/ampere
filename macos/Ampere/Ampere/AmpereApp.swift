//
//  AmpereApp.swift
//  Ampere
//
//  Professional Audio Player
//

import SwiftUI
import AppKit

// ── Window position persistence ────────────────────────────────────────────────
private let kWindowOriginX = "windowOriginX"
private let kWindowOriginY = "windowOriginY"

/// Prefer size applied before SwiftUI finishes laying out content (must match ContentView @AppStorage keys).
private func chromeWidthFromSavedPanelFlags() -> CGFloat {
    let d = UserDefaults.standard
    let base = AmpChrome.windowWidth
    if d.bool(forKey: "showingEQ") { return base + AmpChrome.eqPanelWidth }
    if d.bool(forKey: "showingAlbumArt") { return base + AmpChrome.albumArtPanelWidth }
    return base
}

@main
struct AmpereApp: App {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var themeManager   = ThemeManager()
    @StateObject private var menuBarManager = MenuBarManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerViewModel)
                .environmentObject(playerViewModel.live)
                .environmentObject(themeManager)
                .onAppear {
                    setupWindow()
                    ApplicationsFolderInstallPrompt.checkOnLaunch()
                }
                .onOpenURL { url in
                    // Automatically load and play files opened from Finder
                    playerViewModel.loadFile(url: url)
                    playerViewModel.play()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: AmpChrome.windowWidth, height: 140)
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
            guard let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) else { return }

            // Style
            window.title = "Ampere"
            // If true, AppKit steals horizontal drags before SwiftUI — seek scrubbing breaks. Use WindowDragGesture on chrome instead.
            window.isMovableByWindowBackground = false
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            // Restore saved position
            let defaults = UserDefaults.standard
            if defaults.object(forKey: kWindowOriginX) != nil {
                let x = defaults.double(forKey: kWindowOriginX)
                let y = defaults.double(forKey: kWindowOriginY)
                window.setFrameOrigin(NSPoint(x: x, y: y))
            } else {
                // First launch — center on screen
                window.center()
            }

            // Save position whenever the window moves
            NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: window,
                queue: .main
            ) { _ in
                defaults.set(window.frame.origin.x, forKey: kWindowOriginX)
                defaults.set(window.frame.origin.y, forKey: kWindowOriginY)
            }

            let snap = { applyMainWindowContentWidth(window, requiredWidth: chromeWidthFromSavedPanelFlags()) }
            snap()
            DispatchQueue.main.async(execute: snap)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: snap)
        }
    }
}


