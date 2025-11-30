//
//  ThemeManager.swift
//  Ampere
//
//  Theme management for macOS
//

import SwiftUI
import Combine

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .dark
    
    private let themeKey = "AmpereSelectedTheme"
    
    init() {
        // Load saved theme preference
        loadSavedTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveTheme()
    }
    
    func setThemeByName(_ name: String) {
        if let theme = AppTheme.fromName(name) {
            currentTheme = theme
            saveTheme()
        }
    }
    
    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: themeKey)
    }
    
    private func loadSavedTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: themeKey),
           let theme = AppTheme.fromName(savedTheme) {
            currentTheme = theme
        }
    }
    
    func getAvailableThemes() -> [AppTheme] {
        return AppTheme.allCases
    }
}

enum AppTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case highContrast = "High Contrast"
    case blue = "Blue"
    case green = "Green"
    case purple = "Purple"
    
    static func fromName(_ name: String) -> AppTheme? {
        return AppTheme.allCases.first { $0.rawValue == name }
    }
    
    var colors: ThemeColors {
        switch self {
        case .light:
            return ThemeColors(
                background: Color(red: 0.95, green: 0.95, blue: 0.95),
                surface: Color(red: 1.0, green: 1.0, blue: 1.0),
                primary: Color(red: 0.0, green: 0.48, blue: 0.78),
                secondary: Color(red: 0.5, green: 0.5, blue: 0.5),
                accent: Color(red: 0.0, green: 0.65, blue: 0.93),
                textPrimary: Color(red: 0.0, green: 0.0, blue: 0.0),
                textSecondary: Color(red: 0.4, green: 0.4, blue: 0.4),
                border: Color(red: 0.8, green: 0.8, blue: 0.8),
                controlBackground: Color(red: 0.9, green: 0.9, blue: 0.9),
                controlForeground: Color(red: 0.0, green: 0.0, blue: 0.0),
                success: Color(red: 0.2, green: 0.7, blue: 0.3),
                warning: Color(red: 1.0, green: 0.65, blue: 0.0),
                error: Color(red: 0.9, green: 0.2, blue: 0.2)
            )
        case .dark:
            return ThemeColors(
                background: Color(red: 0.11, green: 0.11, blue: 0.12),
                surface: Color(red: 0.16, green: 0.16, blue: 0.17),
                primary: Color(red: 0.0, green: 0.48, blue: 0.78),
                secondary: Color(red: 0.5, green: 0.5, blue: 0.5),
                accent: Color(red: 0.0, green: 0.65, blue: 0.93),
                textPrimary: Color(red: 1.0, green: 1.0, blue: 1.0),
                textSecondary: Color(red: 0.7, green: 0.7, blue: 0.7),
                border: Color(red: 0.3, green: 0.3, blue: 0.3),
                controlBackground: Color(red: 0.2, green: 0.2, blue: 0.2),
                controlForeground: Color(red: 1.0, green: 1.0, blue: 1.0),
                success: Color(red: 0.3, green: 0.8, blue: 0.4),
                warning: Color(red: 1.0, green: 0.7, blue: 0.2),
                error: Color(red: 1.0, green: 0.3, blue: 0.3)
            )
        case .highContrast:
            return ThemeColors(
                background: Color(red: 0.0, green: 0.0, blue: 0.0),
                surface: Color(red: 0.1, green: 0.1, blue: 0.1),
                primary: Color(red: 1.0, green: 1.0, blue: 1.0),
                secondary: Color(red: 0.8, green: 0.8, blue: 0.8),
                accent: Color(red: 1.0, green: 1.0, blue: 0.0),
                textPrimary: Color(red: 1.0, green: 1.0, blue: 1.0),
                textSecondary: Color(red: 0.9, green: 0.9, blue: 0.9),
                border: Color(red: 1.0, green: 1.0, blue: 1.0),
                controlBackground: Color(red: 0.2, green: 0.2, blue: 0.2),
                controlForeground: Color(red: 1.0, green: 1.0, blue: 1.0),
                success: Color(red: 0.0, green: 1.0, blue: 0.0),
                warning: Color(red: 1.0, green: 1.0, blue: 0.0),
                error: Color(red: 1.0, green: 0.0, blue: 0.0)
            )
        case .blue:
            return ThemeColors(
                background: Color(red: 0.08, green: 0.12, blue: 0.18),
                surface: Color(red: 0.12, green: 0.18, blue: 0.25),
                primary: Color(red: 0.2, green: 0.5, blue: 0.9),
                secondary: Color(red: 0.4, green: 0.6, blue: 0.8),
                accent: Color(red: 0.3, green: 0.7, blue: 1.0),
                textPrimary: Color(red: 0.9, green: 0.95, blue: 1.0),
                textSecondary: Color(red: 0.7, green: 0.8, blue: 0.9),
                border: Color(red: 0.2, green: 0.3, blue: 0.4),
                controlBackground: Color(red: 0.15, green: 0.22, blue: 0.3),
                controlForeground: Color(red: 0.9, green: 0.95, blue: 1.0),
                success: Color(red: 0.3, green: 0.8, blue: 0.5),
                warning: Color(red: 1.0, green: 0.7, blue: 0.3),
                error: Color(red: 1.0, green: 0.4, blue: 0.4)
            )
        case .green:
            return ThemeColors(
                background: Color(red: 0.1, green: 0.15, blue: 0.1),
                surface: Color(red: 0.15, green: 0.22, blue: 0.15),
                primary: Color(red: 0.2, green: 0.7, blue: 0.3),
                secondary: Color(red: 0.4, green: 0.6, blue: 0.4),
                accent: Color(red: 0.3, green: 0.9, blue: 0.4),
                textPrimary: Color(red: 0.95, green: 1.0, blue: 0.95),
                textSecondary: Color(red: 0.8, green: 0.9, blue: 0.8),
                border: Color(red: 0.2, green: 0.3, blue: 0.2),
                controlBackground: Color(red: 0.18, green: 0.25, blue: 0.18),
                controlForeground: Color(red: 0.95, green: 1.0, blue: 0.95),
                success: Color(red: 0.3, green: 0.9, blue: 0.4),
                warning: Color(red: 1.0, green: 0.7, blue: 0.2),
                error: Color(red: 1.0, green: 0.3, blue: 0.3)
            )
        case .purple:
            return ThemeColors(
                background: Color(red: 0.15, green: 0.1, blue: 0.18),
                surface: Color(red: 0.2, green: 0.15, blue: 0.22),
                primary: Color(red: 0.6, green: 0.3, blue: 0.9),
                secondary: Color(red: 0.7, green: 0.5, blue: 0.8),
                accent: Color(red: 0.8, green: 0.4, blue: 1.0),
                textPrimary: Color(red: 1.0, green: 0.95, blue: 1.0),
                textSecondary: Color(red: 0.9, green: 0.85, blue: 0.9),
                border: Color(red: 0.3, green: 0.2, blue: 0.35),
                controlBackground: Color(red: 0.22, green: 0.18, blue: 0.25),
                controlForeground: Color(red: 1.0, green: 0.95, blue: 1.0),
                success: Color(red: 0.4, green: 0.9, blue: 0.5),
                warning: Color(red: 1.0, green: 0.7, blue: 0.3),
                error: Color(red: 1.0, green: 0.3, blue: 0.3)
            )
        }
    }
}

struct ThemeColors {
    let background: Color
    let surface: Color
    let primary: Color
    let secondary: Color
    let accent: Color
    let textPrimary: Color
    let textSecondary: Color
    let border: Color
    let controlBackground: Color
    let controlForeground: Color
    let success: Color
    let warning: Color
    let error: Color
}

