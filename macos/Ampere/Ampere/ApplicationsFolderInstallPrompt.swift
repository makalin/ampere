//
//  ApplicationsFolderInstallPrompt.swift
//  Ampere
//
//  Sandboxed apps cannot reliably copy themselves into /Applications (permission +
//  busy files). We only detect “installed” locations robustly and offer Finder help.
//

import AppKit

enum ApplicationsFolderInstallPrompt {

    private static let suppressKey = "suppressApplicationsFolderInstallPrompt"
    private static let gate = NSLock()
    private static var didScheduleThisProcess = false

    static func checkOnLaunch() {
        gate.lock()
        defer { gate.unlock() }
        guard !didScheduleThisProcess else { return }
        didScheduleThisProcess = true

        guard !UserDefaults.standard.bool(forKey: suppressKey) else { return }
        guard !shouldSkipInstallPromptEntirely() else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            NSApp.activate(ignoringOtherApps: true)
            presentFinderHelpPrompt()
        }
    }

    // MARK: - When we skip (no dialog)

    private static func shouldSkipInstallPromptEntirely() -> Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" { return true }
        return isRunningFromApplicationsFolder()
    }

    /// True if the app is on disk under `/Applications` or `~/Applications` (resolved symlinks, subfolders allowed).
    static func isRunningFromApplicationsFolder(bundleURL: URL = Bundle.main.bundleURL) -> Bool {
        let path = bundleURL.resolvingSymlinksInPath().path

        // Local builds — don’t nag during development.
        if path.contains("/DerivedData/") { return true }
        if path.contains("/Build/Products/") { return true }

        return isBundlePathUnderApplicationsRoots(path)
    }

    private static func isBundlePathUnderApplicationsRoots(_ bundlePath: String) -> Bool {
        let apps = URL(fileURLWithPath: "/Applications", isDirectory: true)
            .resolvingSymlinksInPath().standardizedFileURL.path + "/"
        let userApps = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications", isDirectory: true)
            .resolvingSymlinksInPath().standardizedFileURL.path + "/"

        // Primary: app lives anywhere under …/Applications/… (handles /System/Volumes/Data/Applications/…)
        if bundlePath.hasPrefix(apps) { return true }
        if bundlePath.hasPrefix(userApps) { return true }

        // Fallback: compare parent directory (some bundle URLs normalize differently)
        let parent = URL(fileURLWithPath: (bundlePath as NSString).deletingLastPathComponent)
            .resolvingSymlinksInPath().standardizedFileURL.path
        let appsParent = String(apps.dropLast())
        let userAppsParent = String(userApps.dropLast())
        if parent.caseInsensitiveCompare(appsParent) == .orderedSame { return true }
        if parent.caseInsensitiveCompare(userAppsParent) == .orderedSame { return true }

        return false
    }

    // MARK: - Dialog (Finder only — no broken auto-copy)

    private static func presentFinderHelpPrompt() {
        let alert = NSAlert()
        alert.messageText = "Keep Ampere in Applications"
        alert.informativeText = "Put Ampere in your Applications folder so the Dock, Spotlight, and audio files can find it.\n\nChoose Reveal in Finder, then drag Ampere onto Applications (or use Open Applications and drag it there)."
        alert.alertStyle = .informational
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Don’t show again"

        alert.addButton(withTitle: "Reveal in Finder")
        alert.addButton(withTitle: "Open Applications")
        alert.addButton(withTitle: "OK")

        let response = alert.runModal()
        if alert.suppressionButton?.state == .on {
            UserDefaults.standard.set(true, forKey: suppressKey)
        }

        switch response {
        case .alertFirstButtonReturn:
            NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
        case .alertSecondButtonReturn:
            NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications", isDirectory: true))
        default:
            break
        }
    }
}
