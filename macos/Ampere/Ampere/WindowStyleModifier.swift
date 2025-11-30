//
//  WindowStyleModifier.swift
//  Ampere
//
//  Custom window style for borderless Winamp look
//

import SwiftUI
import AppKit

struct BorderlessWindow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor())
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                // Make window borderless but keep it movable
                window.styleMask = [.borderless, .fullSizeContentView]
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = true // Enable shadow for better visual depth
                window.isMovableByWindowBackground = true
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}

extension View {
    func borderlessWindow() -> some View {
        modifier(BorderlessWindow())
    }
}

