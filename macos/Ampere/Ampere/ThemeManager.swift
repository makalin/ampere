//
//  ThemeManager.swift
//  Ampere
//
//  Skin / Theme management — supports colour themes AND image-based skins.
//  Place a skin folder in ~/Library/Application Support/Ampere/Skins/<SkinName>/
//  The folder should contain: main.png, eq.png, playlist.png (optional).
//

import SwiftUI
import Combine
import AppKit

// ─── MARK: Skin Colors ────────────────────────────────────────────────────────

struct SkinColors {
    // Panels
    var panelDeep:     Color
    var panelDark:     Color
    var panelMid:      Color
    var panelLight:    Color

    // Bevels
    var bevelHigh:     Color
    var bevelShadow:   Color

    // Accent green
    var neonGreen:     Color
    var neonGreenDim:  Color
    var neonGreenFade: Color

    // Amber
    var amber:         Color
    var amberDim:      Color

    // Text
    var textBright:    Color
    var textMid:       Color
    var textDim:       Color

    // Display
    var displayBg:     Color
    var displayScanAlt:Color

    // Track
    var trackBg:       Color
}

// ─── MARK: Built-In Themes ────────────────────────────────────────────────────

enum BuiltInTheme: String, CaseIterable, Identifiable {
    case classic    = "Classic"
    case amber      = "Amber"
    case blue       = "Blue Ice"
    case purple     = "Purple"
    case stealth    = "Stealth"
    case retro      = "Retro Green"

    var id: String { rawValue }

    var colors: SkinColors {
        switch self {
        case .classic:
            return SkinColors(
                panelDeep:      Color(red: 0.05, green: 0.06, blue: 0.04),
                panelDark:      Color(red: 0.10, green: 0.12, blue: 0.08),
                panelMid:       Color(red: 0.14, green: 0.16, blue: 0.11),
                panelLight:     Color(red: 0.20, green: 0.22, blue: 0.16),
                bevelHigh:      Color(red: 0.38, green: 0.40, blue: 0.32),
                bevelShadow:    Color(red: 0.02, green: 0.02, blue: 0.02),
                neonGreen:      Color(red: 0.0,  green: 1.00, blue: 0.255),
                neonGreenDim:   Color(red: 0.0,  green: 0.55, blue: 0.14),
                neonGreenFade:  Color(red: 0.0,  green: 0.25, blue: 0.07),
                amber:          Color(red: 1.00, green: 0.40, blue: 0.00),
                amberDim:       Color(red: 0.60, green: 0.24, blue: 0.00),
                textBright:     Color(red: 0.85, green: 0.95, blue: 0.72),
                textMid:        Color(red: 0.50, green: 0.58, blue: 0.40),
                textDim:        Color(red: 0.28, green: 0.32, blue: 0.22),
                displayBg:      Color(red: 0.02, green: 0.05, blue: 0.01),
                displayScanAlt: Color(red: 0.06, green: 0.08, blue: 0.04),
                trackBg:        Color(red: 0.07, green: 0.09, blue: 0.05)
            )
        case .amber:
            return SkinColors(
                panelDeep:      Color(red: 0.06, green: 0.04, blue: 0.01),
                panelDark:      Color(red: 0.12, green: 0.09, blue: 0.02),
                panelMid:       Color(red: 0.17, green: 0.13, blue: 0.04),
                panelLight:     Color(red: 0.24, green: 0.18, blue: 0.06),
                bevelHigh:      Color(red: 0.45, green: 0.35, blue: 0.15),
                bevelShadow:    Color(red: 0.02, green: 0.01, blue: 0.00),
                neonGreen:      Color(red: 1.00, green: 0.65, blue: 0.00),
                neonGreenDim:   Color(red: 0.65, green: 0.38, blue: 0.00),
                neonGreenFade:  Color(red: 0.30, green: 0.18, blue: 0.00),
                amber:          Color(red: 1.00, green: 0.85, blue: 0.10),
                amberDim:       Color(red: 0.65, green: 0.50, blue: 0.05),
                textBright:     Color(red: 1.00, green: 0.92, blue: 0.70),
                textMid:        Color(red: 0.70, green: 0.58, blue: 0.30),
                textDim:        Color(red: 0.38, green: 0.30, blue: 0.12),
                displayBg:      Color(red: 0.04, green: 0.03, blue: 0.00),
                displayScanAlt: Color(red: 0.08, green: 0.06, blue: 0.01),
                trackBg:        Color(red: 0.08, green: 0.06, blue: 0.01)
            )
        case .blue:
            return SkinColors(
                panelDeep:      Color(red: 0.02, green: 0.04, blue: 0.10),
                panelDark:      Color(red: 0.05, green: 0.08, blue: 0.16),
                panelMid:       Color(red: 0.08, green: 0.12, blue: 0.22),
                panelLight:     Color(red: 0.13, green: 0.18, blue: 0.30),
                bevelHigh:      Color(red: 0.25, green: 0.35, blue: 0.55),
                bevelShadow:    Color(red: 0.01, green: 0.02, blue: 0.05),
                neonGreen:      Color(red: 0.10, green: 0.65, blue: 1.00),
                neonGreenDim:   Color(red: 0.05, green: 0.35, blue: 0.65),
                neonGreenFade:  Color(red: 0.02, green: 0.15, blue: 0.30),
                amber:          Color(red: 0.40, green: 0.80, blue: 1.00),
                amberDim:       Color(red: 0.20, green: 0.50, blue: 0.70),
                textBright:     Color(red: 0.80, green: 0.92, blue: 1.00),
                textMid:        Color(red: 0.45, green: 0.60, blue: 0.80),
                textDim:        Color(red: 0.22, green: 0.32, blue: 0.50),
                displayBg:      Color(red: 0.01, green: 0.02, blue: 0.07),
                displayScanAlt: Color(red: 0.03, green: 0.05, blue: 0.12),
                trackBg:        Color(red: 0.03, green: 0.05, blue: 0.12)
            )
        case .purple:
            return SkinColors(
                panelDeep:      Color(red: 0.05, green: 0.02, blue: 0.09),
                panelDark:      Color(red: 0.09, green: 0.04, blue: 0.15),
                panelMid:       Color(red: 0.13, green: 0.07, blue: 0.21),
                panelLight:     Color(red: 0.20, green: 0.12, blue: 0.30),
                bevelHigh:      Color(red: 0.40, green: 0.25, blue: 0.55),
                bevelShadow:    Color(red: 0.02, green: 0.01, blue: 0.04),
                neonGreen:      Color(red: 0.85, green: 0.30, blue: 1.00),
                neonGreenDim:   Color(red: 0.50, green: 0.15, blue: 0.65),
                neonGreenFade:  Color(red: 0.22, green: 0.06, blue: 0.30),
                amber:          Color(red: 1.00, green: 0.55, blue: 0.90),
                amberDim:       Color(red: 0.60, green: 0.28, blue: 0.55),
                textBright:     Color(red: 0.95, green: 0.85, blue: 1.00),
                textMid:        Color(red: 0.65, green: 0.50, blue: 0.78),
                textDim:        Color(red: 0.32, green: 0.22, blue: 0.42),
                displayBg:      Color(red: 0.02, green: 0.01, blue: 0.05),
                displayScanAlt: Color(red: 0.06, green: 0.03, blue: 0.10),
                trackBg:        Color(red: 0.06, green: 0.03, blue: 0.10)
            )
        case .stealth:
            return SkinColors(
                panelDeep:      Color(red: 0.04, green: 0.04, blue: 0.04),
                panelDark:      Color(red: 0.08, green: 0.08, blue: 0.08),
                panelMid:       Color(red: 0.12, green: 0.12, blue: 0.12),
                panelLight:     Color(red: 0.18, green: 0.18, blue: 0.18),
                bevelHigh:      Color(red: 0.35, green: 0.35, blue: 0.35),
                bevelShadow:    Color(red: 0.01, green: 0.01, blue: 0.01),
                neonGreen:      Color(red: 0.90, green: 0.90, blue: 0.90),
                neonGreenDim:   Color(red: 0.50, green: 0.50, blue: 0.50),
                neonGreenFade:  Color(red: 0.22, green: 0.22, blue: 0.22),
                amber:          Color(red: 0.75, green: 0.75, blue: 0.75),
                amberDim:       Color(red: 0.45, green: 0.45, blue: 0.45),
                textBright:     Color(red: 0.95, green: 0.95, blue: 0.95),
                textMid:        Color(red: 0.60, green: 0.60, blue: 0.60),
                textDim:        Color(red: 0.30, green: 0.30, blue: 0.30),
                displayBg:      Color(red: 0.02, green: 0.02, blue: 0.02),
                displayScanAlt: Color(red: 0.06, green: 0.06, blue: 0.06),
                trackBg:        Color(red: 0.06, green: 0.06, blue: 0.06)
            )
        case .retro:
            return SkinColors(
                panelDeep:      Color(red: 0.00, green: 0.07, blue: 0.00),
                panelDark:      Color(red: 0.00, green: 0.12, blue: 0.00),
                panelMid:       Color(red: 0.02, green: 0.17, blue: 0.02),
                panelLight:     Color(red: 0.04, green: 0.24, blue: 0.04),
                bevelHigh:      Color(red: 0.10, green: 0.45, blue: 0.10),
                bevelShadow:    Color(red: 0.00, green: 0.02, blue: 0.00),
                neonGreen:      Color(red: 0.15, green: 1.00, blue: 0.15),
                neonGreenDim:   Color(red: 0.05, green: 0.55, blue: 0.05),
                neonGreenFade:  Color(red: 0.02, green: 0.25, blue: 0.02),
                amber:          Color(red: 0.80, green: 1.00, blue: 0.20),
                amberDim:       Color(red: 0.45, green: 0.60, blue: 0.10),
                textBright:     Color(red: 0.70, green: 1.00, blue: 0.70),
                textMid:        Color(red: 0.35, green: 0.65, blue: 0.35),
                textDim:        Color(red: 0.15, green: 0.38, blue: 0.15),
                displayBg:      Color(red: 0.00, green: 0.04, blue: 0.00),
                displayScanAlt: Color(red: 0.01, green: 0.08, blue: 0.01),
                trackBg:        Color(red: 0.01, green: 0.06, blue: 0.01)
            )
        }
    }

    /// Accent swatch for preview tiles
    var previewAccent: Color {
        switch self {
        case .classic: return Color(red: 0.0, green: 1.0, blue: 0.25)
        case .amber:   return Color(red: 1.0, green: 0.65, blue: 0.0)
        case .blue:    return Color(red: 0.1, green: 0.65, blue: 1.0)
        case .purple:  return Color(red: 0.85, green: 0.3, blue: 1.0)
        case .stealth: return Color(red: 0.9, green: 0.9, blue: 0.9)
        case .retro:   return Color(red: 0.15, green: 1.0, blue: 0.15)
        }
    }

    var previewPanel: Color {
        colors.panelMid
    }
}

// ─── MARK: Skin Entry (custom image-based skin) ───────────────────────────────

struct CustomSkin: Identifiable, Equatable {
    let id: UUID
    let name: String
    let folderURL: URL
    /// Optional preview thumbnail loaded from skin folder
    var thumbnail: NSImage?

    init(name: String, folderURL: URL) {
        self.id = UUID()
        self.name = name
        self.folderURL = folderURL
        // Try to load a preview image
        let candidates = ["preview.png", "preview.jpg", "main.png"]
        for c in candidates {
            let imgURL = folderURL.appendingPathComponent(c)
            if let img = NSImage(contentsOf: imgURL) {
                thumbnail = img
                break
            }
        }
    }
}

// ─── MARK: ThemeManager ───────────────────────────────────────────────────────

class ThemeManager: ObservableObject {
    @Published var activeTheme: BuiltInTheme = .classic
    @Published var customSkins: [CustomSkin] = []
    @Published var activeCustomSkinId: UUID? = nil

    private let themeKey     = "AmpereBuiltInTheme"
    private let customSkinKey = "AmpereCustomSkin"

    var colors: SkinColors { activeTheme.colors }

    // Back-compat: expose as AppTheme for legacy callers
    var currentTheme: AppTheme {
        get {
            switch activeTheme {
            case .classic: return .green
            case .amber:   return .dark
            case .blue:    return .blue
            case .purple:  return .purple
            case .stealth: return .highContrast
            case .retro:   return .green
            }
        }
        set { /* no-op, use setTheme(_:) */ }
    }

    init() {
        loadSavedTheme()
        scanCustomSkins()
    }

    func setTheme(_ theme: BuiltInTheme) {
        activeTheme = theme
        activeCustomSkinId = nil
        UserDefaults.standard.set(theme.rawValue, forKey: themeKey)
    }

    // Back-compat
    func setTheme(_ theme: AppTheme) {
        switch theme {
        case .dark, .light, .highContrast: setTheme(BuiltInTheme.stealth)
        case .blue:   setTheme(BuiltInTheme.blue)
        case .green:  setTheme(BuiltInTheme.classic)
        case .purple: setTheme(BuiltInTheme.purple)
        }
    }

    func activateCustomSkin(_ skin: CustomSkin) {
        activeCustomSkinId = skin.id
        UserDefaults.standard.set(skin.name, forKey: customSkinKey)
    }

    func scanCustomSkins() {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let skinsDir = support.appendingPathComponent("Ampere/Skins")
        try? FileManager.default.createDirectory(at: skinsDir, withIntermediateDirectories: true)
        let dirs = (try? FileManager.default.contentsOfDirectory(at: skinsDir, includingPropertiesForKeys: [.isDirectoryKey])) ?? []
        customSkins = dirs
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map { CustomSkin(name: $0.lastPathComponent, folderURL: $0) }
    }

    private func loadSavedTheme() {
        if let raw = UserDefaults.standard.string(forKey: themeKey),
           let t = BuiltInTheme(rawValue: raw) {
            activeTheme = t
        }
    }

    // MARK: - Legacy AppTheme support
    func getAvailableThemes() -> [AppTheme] { AppTheme.allCases }
    func setThemeByName(_ name: String) {
        if let t = BuiltInTheme(rawValue: name) { setTheme(t) }
    }
}

// ─── MARK: Legacy AppTheme (kept for any remaining callsites) ─────────────────

enum AppTheme: String, CaseIterable {
    case light        = "Light"
    case dark         = "Dark"
    case highContrast = "High Contrast"
    case blue         = "Blue"
    case green        = "Green"
    case purple       = "Purple"

    static func fromName(_ name: String) -> AppTheme? {
        AppTheme.allCases.first { $0.rawValue == name }
    }

    var colors: ThemeColors {
        ThemeColors(
            background:       .black,
            surface:          .black,
            primary:          .green,
            secondary:        .gray,
            accent:           .green,
            textPrimary:      .white,
            textSecondary:    .gray,
            border:           .gray,
            controlBackground:.black,
            controlForeground:.white,
            success:          .green,
            warning:          .yellow,
            error:            .red
        )
    }
}

struct ThemeColors {
    let background:       Color
    let surface:          Color
    let primary:          Color
    let secondary:        Color
    let accent:           Color
    let textPrimary:      Color
    let textSecondary:    Color
    let border:           Color
    let controlBackground:Color
    let controlForeground:Color
    let success:          Color
    let warning:          Color
    let error:            Color
}
