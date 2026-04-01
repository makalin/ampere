//
//  AmpereDesignSystem.swift
//  Ampere
//
//  Unified bitmap-style Winamp design tokens and reusable components.
//  Colors now sourced from ThemeManager via AmpSkin environment key.
//

import SwiftUI
import AppKit

// ─── MARK: Environment Key for Active Skin ───────────────────────────────────

struct AmpSkinKey: EnvironmentKey {
    static let defaultValue: SkinColors = BuiltInTheme.classic.colors
}

extension EnvironmentValues {
    var ampSkin: SkinColors {
        get { self[AmpSkinKey.self] }
        set { self[AmpSkinKey.self] = newValue }
    }
}

// ─── MARK: Static Color Palette (default = Classic skin) ─────────────────────
// Used by views that haven't yet been updated to @Environment(\.ampSkin).
// These are overridden at runtime via the environment.

enum AmpColor {
    // Base panels
    static var panelDeep:      Color { _skin.panelDeep }
    static var panelDark:      Color { _skin.panelDark }
    static var panelMid:       Color { _skin.panelMid }
    static var panelLight:     Color { _skin.panelLight }

    // Bevel highlights / shadows
    static var bevelHigh:      Color { _skin.bevelHigh }
    static var bevelShadow:    Color { _skin.bevelShadow }

    // Accent
    static var neonGreen:      Color { _skin.neonGreen }
    static var neonGreenDim:   Color { _skin.neonGreenDim }
    static var neonGreenFade:  Color { _skin.neonGreenFade }

    // Amber
    static var amber:          Color { _skin.amber }
    static var amberDim:       Color { _skin.amberDim }

    // Text
    static var textBright:     Color { _skin.textBright }
    static var textMid:        Color { _skin.textMid }
    static var textDim:        Color { _skin.textDim }

    // Display (LCD / CRT)
    static var displayBg:      Color { _skin.displayBg }
    static var displayScanAlt: Color { _skin.displayScanAlt }

    // Seekbar / track
    static var trackBg:        Color { _skin.trackBg }

    /// Updated any time ThemeManager publishes a change.
    static var _skin: SkinColors = BuiltInTheme.classic.colors
}

// ─── MARK: View Modifier: apply skin to subtree ───────────────────────────────

struct SkinApplier: ViewModifier {
    @ObservedObject var themeManager: ThemeManager
    func body(content: Content) -> some View {
        content
            .environment(\.ampSkin, themeManager.colors)
            .onReceive(themeManager.$activeTheme) { _ in
                AmpColor._skin = themeManager.colors
            }
    }
}

extension View {
    func applySkin(_ themeManager: ThemeManager) -> some View {
        modifier(SkinApplier(themeManager: themeManager))
            .onAppear { AmpColor._skin = themeManager.colors }
    }
}

// ─── MARK: Typography ────────────────────────────────────────────────────────

extension Font {
    static func ampMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    static func ampDigital(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

// ─── MARK: Bevel Box ─────────────────────────────────────────────────────────
// Classic embossed / inset bitmap panel

struct BevelBox: View {
    enum Style { case raised, inset }
    let style: Style
    let content: AnyView

    init(style: Style = .raised, @ViewBuilder content: () -> some View) {
        self.style = style
        self.content = AnyView(content())
    }

    var body: some View {
        content
            .background(style == .raised ? AmpColor.panelLight : AmpColor.displayBg)
            .overlay(
                ZStack {
                    // Top + left edge
                    VStack(spacing: 0) {
                        Rectangle().fill(style == .raised ? AmpColor.bevelHigh : AmpColor.bevelShadow).frame(height: 1)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Rectangle().fill(style == .raised ? AmpColor.bevelHigh : AmpColor.bevelShadow).frame(width: 1)
                        Spacer()
                    }
                    // Bottom + right edge
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle().fill(style == .raised ? AmpColor.bevelShadow : AmpColor.bevelHigh).frame(height: 1)
                    }
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle().fill(style == .raised ? AmpColor.bevelShadow : AmpColor.bevelHigh).frame(width: 1)
                    }
                }
            )
    }
}

// ─── MARK: LCD Display Background ────────────────────────────────────────────

struct LcdBackground: View {
    var body: some View {
        ZStack {
            AmpColor.displayBg
            GeometryReader { geo in
                let lines = Int(geo.size.height / 2)
                VStack(spacing: 0) {
                    ForEach(0..<lines, id: \.self) { _ in
                        AmpColor.displayScanAlt.frame(height: 1)
                        Color.clear.frame(height: 1)
                    }
                }
            }
        }
    }
}

// ─── MARK: Amp Button ────────────────────────────────────────────────────────

struct AmpButton: View {
    let label: String
    let icon: String?
    let isActive: Bool
    let width: CGFloat
    let height: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(
        label: String = "",
        icon: String? = nil,
        isActive: Bool = false,
        width: CGFloat = 22,
        height: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.isActive = isActive
        self.width = width
        self.height = height
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                (isPressed ? AmpColor.panelDark : AmpColor.panelLight)
                ZStack {
                    VStack(spacing: 0) {
                        Rectangle().fill(isPressed ? AmpColor.bevelShadow : AmpColor.bevelHigh).frame(height: 1)
                        Spacer()
                        Rectangle().fill(isPressed ? AmpColor.bevelHigh : AmpColor.bevelShadow).frame(height: 1)
                    }
                    HStack(spacing: 0) {
                        Rectangle().fill(isPressed ? AmpColor.bevelShadow : AmpColor.bevelHigh).frame(width: 1)
                        Spacer()
                        Rectangle().fill(isPressed ? AmpColor.bevelHigh : AmpColor.bevelShadow).frame(width: 1)
                    }
                }
                Group {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.ampMono(height * 0.45, weight: .bold))
                            .foregroundColor(isActive ? AmpColor.neonGreen : AmpColor.textBright)
                            .shadow(color: isActive ? AmpColor.neonGreen.opacity(0.8) : .clear, radius: 3)
                    } else if !label.isEmpty {
                        Text(label)
                            .font(.ampMono(7, weight: .bold))
                            .foregroundColor(isActive ? AmpColor.neonGreen : AmpColor.textBright)
                            .shadow(color: isActive ? AmpColor.neonGreen.opacity(0.8) : .clear, radius: 2)
                    }
                }
            }
            .frame(width: width, height: height)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }
}

// ─── MARK: Segment LED Display ───────────────────────────────────────────────

struct LedDigitDisplay: View {
    let text: String
    let size: CGFloat
    var color: Color = AmpColor.neonGreen

    var body: some View {
        ZStack(alignment: .leading) {
            Text(text.map { _ in "8" }.joined())
                .font(.ampDigital(size))
                .foregroundColor(AmpColor.neonGreenFade)
                .kerning(1.5)
            Text(text)
                .font(.ampDigital(size))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 2)
                .kerning(1.5)
        }
    }
}

// ─── MARK: Mini Spectrum Bars ─────────────────────────────────────────────────

struct MiniSpectrumView: View {
    let bands: [Float]
    let barWidth: CGFloat
    let maxHeight: CGFloat

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<min(bands.count, 20), id: \.self) { i in
                let h = max(2, CGFloat(bands[i]) * maxHeight)
                VStack(spacing: 0) {
                    Spacer()
                    spectrumBar(height: h, maxH: maxHeight)
                        .frame(width: barWidth, height: h)
                        .animation(.linear(duration: 0.04), value: bands[i])
                }
                .frame(width: barWidth, height: maxHeight)
            }
        }
    }

    private func spectrumBar(height: CGFloat, maxH: CGFloat) -> some View {
        let pct = height / maxH
        let color: Color
        if pct > 0.80      { color = Color(red: 1.0, green: 0.15, blue: 0.0) }
        else if pct > 0.55 { color = Color(red: 1.0, green: 0.65, blue: 0.0) }
        else               { color = AmpColor.neonGreen }
        return LinearGradient(
            gradient: Gradient(colors: [color.opacity(0.4), color]),
            startPoint: .top, endPoint: .bottom
        )
    }
}

// ─── MARK: Scrolling Marquee Text ────────────────────────────────────────────

struct MarqueeText: View {
    let text: String
    let font: Font
    let color: Color
    let width: CGFloat
    @State private var offset: CGFloat = 0
    @State private var textWidth: CGFloat = 0

    var body: some View {
        GeometryReader { _ in
            Text(text + "   " + text)
                .font(font)
                .foregroundColor(color)
                .shadow(color: color.opacity(0.5), radius: 2)
                .fixedSize()
                .offset(x: offset)
                .onAppear {
                    textWidth = CGFloat(text.count) * 7
                    startAnimation()
                }
                .onChange(of: text) { _ in
                    offset = 0
                    startAnimation()
                }
        }
        .frame(width: width)
        .clipped()
    }

    private func startAnimation() {
        guard textWidth > width else { return }
        withAnimation(
            .linear(duration: Double(textWidth) * 0.05)
            .repeatForever(autoreverses: false)
        ) {
            offset = -textWidth
        }
    }
}
