//
//  AmpereDesignSystem.swift
//  Ampere
//
//  Unified bitmap-style Winamp design tokens and reusable components
//

import SwiftUI
import AppKit

// ─── MARK: Color Palette ─────────────────────────────────────────────────────

enum AmpColor {
    // Base panels
    static let panelDeep      = Color(red: 0.05, green: 0.06, blue: 0.04)   // #0d0f0b near black
    static let panelDark      = Color(red: 0.10, green: 0.12, blue: 0.08)   // #1a1f14 dark olive
    static let panelMid       = Color(red: 0.14, green: 0.16, blue: 0.11)   // panel mid
    static let panelLight     = Color(red: 0.20, green: 0.22, blue: 0.16)   // #333827 raised panel

    // Bevel highlights / shadows
    static let bevelHigh      = Color(red: 0.38, green: 0.40, blue: 0.32)   // top-left bevel
    static let bevelShadow    = Color(red: 0.02, green: 0.02, blue: 0.02)   // bottom-right bevel

    // Accent — electric green
    static let neonGreen      = Color(red: 0.0,  green: 1.00, blue: 0.255)  // #00FF41
    static let neonGreenDim   = Color(red: 0.0,  green: 0.55, blue: 0.14)   // dim green
    static let neonGreenFade  = Color(red: 0.0,  green: 0.25, blue: 0.07)   // very dim

    // Accent — orange / amber
    static let amber          = Color(red: 1.00, green: 0.40, blue: 0.00)   // #ff6600
    static let amberDim       = Color(red: 0.60, green: 0.24, blue: 0.00)

    // Text
    static let textBright     = Color(red: 0.85, green: 0.95, blue: 0.72)
    static let textMid        = Color(red: 0.50, green: 0.58, blue: 0.40)
    static let textDim        = Color(red: 0.28, green: 0.32, blue: 0.22)

    // Display (LCD / CRT)
    static let displayBg      = Color(red: 0.02, green: 0.05, blue: 0.01)
    static let displayScanAlt = Color(red: 0.06, green: 0.08, blue: 0.04)

    // Seekbar / track
    static let trackBg        = Color(red: 0.07, green: 0.09, blue: 0.05)
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
            // Subtle scanline effect
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
                // Base fill – inset when pressed
                (isPressed ? AmpColor.panelDark : AmpColor.panelLight)

                // Bevel overlay
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

                // Content
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
            // Dim background ghost characters for LCD feel
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
                    // Color gradient: green → yellow → red at top
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
        if pct > 0.80 { color = Color(red: 1.0, green: 0.15, blue: 0.0) }
        else if pct > 0.55 { color = Color(red: 1.0, green: 0.65, blue: 0.0) }
        else { color = AmpColor.neonGreen }

        return LinearGradient(
            gradient: Gradient(colors: [color.opacity(0.4), color]),
            startPoint: .top,
            endPoint: .bottom
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
        GeometryReader { geo in
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
