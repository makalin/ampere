//
//  WindowStyleModifier.swift
//  Ampere
//
//  Custom window style for borderless Winamp look
//

import SwiftUI
import AppKit

// MARK: - Match NSWindow width to SwiftUI chrome (no side gutters; expands when EQ/settings/etc. open)

/// Locks horizontal resize to `requiredWidth` and snaps the window if AppKit/SwiftUI left it wider than the skin.
func applyMainWindowContentWidth(_ window: NSWindow, requiredWidth: CGFloat) {
    let ww = max(requiredWidth, AmpChrome.windowWidth)
    window.contentMinSize = NSSize(width: ww, height: 80)
    window.contentMaxSize = NSSize(width: ww, height: 10_000)

    let contentRect = window.contentRect(forFrameRect: window.frame)
    guard abs(contentRect.width - ww) > 0.5 else { return }

    var newContent = contentRect
    newContent.size.width = ww
    let newFrame = window.frameRect(forContentRect: newContent)
    window.setFrame(newFrame, display: true, animate: false)
}

/// Bridges SwiftUI’s ideal horizontal chrome width to AppKit so the window never stays wider than the layout (which caused empty side gutters).
struct MainWindowWidthSync: NSViewRepresentable {
    var requiredWidth: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.scheduleApply(for: view, width: requiredWidth)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.scheduleApply(for: nsView, width: requiredWidth)
    }

    final class Coordinator {
        private var resizeObs: NSObjectProtocol?
        /// Latest width from SwiftUI; resize callbacks must use this, not a stale captured value.
        private var latestWidth: CGFloat = AmpChrome.windowWidth

        deinit {
            if let resizeObs {
                NotificationCenter.default.removeObserver(resizeObs)
            }
        }

        func scheduleApply(for view: NSView, width: CGFloat) {
            latestWidth = width
            DispatchQueue.main.async { [weak self] in
                self?.applyIfPossible(view: view, width: width, attempt: 0)
            }
        }

        private func applyIfPossible(view: NSView, width: CGFloat, attempt: Int) {
            latestWidth = width
            guard let window = view.window else {
                if attempt < 15 {
                    DispatchQueue.main.async { [weak self] in
                        self?.applyIfPossible(view: view, width: width, attempt: attempt + 1)
                    }
                }
                return
            }
            applyMainWindowContentWidth(window, requiredWidth: latestWidth)
            if resizeObs == nil {
                resizeObs = NotificationCenter.default.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: window,
                    queue: .main
                ) { [weak self] note in
                    guard let self, let w = note.object as? NSWindow else { return }
                    applyMainWindowContentWidth(w, requiredWidth: self.latestWidth)
                }
            }
        }
    }
}

struct BorderlessWindow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(WindowAccessor())
    }
}

struct WindowAccessor: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.configureWhenAttached(view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.configureWhenAttached(nsView)
    }

    final class Coordinator {
        func configureWhenAttached(_ view: NSView, attempt: Int = 0) {
            DispatchQueue.main.async {
                if let window = view.window {
                    // Make window borderless but keep it movable
                    window.styleMask = [.borderless, .fullSizeContentView]
                    window.isOpaque = false
                    window.backgroundColor = .clear
                    window.hasShadow = false // Disable aggregate shadow to avoid dark outlines around multi-window layouts
                    window.isMovableByWindowBackground = false
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                } else if attempt < 12 {
                    self.configureWhenAttached(view, attempt: attempt + 1)
                }
            }
        }
    }
}

extension View {
    func borderlessWindow() -> some View {
        modifier(BorderlessWindow())
    }
}

