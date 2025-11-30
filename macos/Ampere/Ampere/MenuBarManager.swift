//
//  MenuBarManager.swift
//  Ampere
//
//  Menu bar status item for Ampere
//

import AppKit
import SwiftUI
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?
    
    init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Set icon
            if let image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Ampere") {
                image.isTemplate = true
                button.image = image
            }
            button.toolTip = "Ampere Audio Player"
            button.action = #selector(menuBarButtonClicked)
            button.target = self
        }
        
        // Create menu
        menu = NSMenu()
        let appItem = NSMenuItem(title: "Ampere", action: nil, keyEquivalent: "")
        appItem.isEnabled = false
        menu?.addItem(appItem)
        menu?.addItem(NSMenuItem.separator())
        
        let showItem = NSMenuItem(title: "Show Player", action: #selector(showPlayer), keyEquivalent: "")
        showItem.target = self
        menu?.addItem(showItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit Ampere", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu?.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    private var mainWindow: NSWindow? {
        return NSApplication.shared.windows.first { window in
            // Filter out status bar windows (which usually can't become key)
            // and look for our main window
            return window.canBecomeKey && window.title == "Ampere"
        }
    }
    
    @objc private func menuBarButtonClicked() {
        // Show/hide main window
        if let window = mainWindow {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            // Fallback: try to find any window that looks like ours
            if let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    @objc private func showPlayer() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else if let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

