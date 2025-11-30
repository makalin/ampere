//
//  WinampEQDisplay.swift
//  Ampere
//
//  Professional Winamp-style EQ spectrum analyzer display
//

import SwiftUI
import AppKit

struct WinampEQDisplay: View {
    @Binding var frequencyBands: [Float]
    let width: CGFloat
    let height: CGFloat
    
    // Frequency labels for 10 bands
    private let frequencyLabels = ["60", "170", "310", "600", "1K", "3K", "6K", "12K", "14K", "16K"]
    // dB scale markers
    private let dbMarkers: [CGFloat] = [0.0, 0.25, 0.5, 0.75, 1.0] // 0%, 25%, 50%, 75%, 100%
    private let dbLabels = ["-12", "-6", "0", "+6", "+12"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Dark background with subtle gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.0, blue: 0.0),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Professional grid with frequency and dB markings
            professionalGrid
            
            // Frequency bars with detailed styling
            HStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    detailedFrequencyBar(index: index)
                }
            }
            
            // Overlay frequency labels at bottom
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<10, id: \.self) { index in
                        Text(frequencyLabels[index])
                            .font(.system(size: 7, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.7))
                            .frame(width: width / 10.0)
                    }
                }
                .padding(.bottom, 2)
            }
            .allowsHitTesting(false)
            
            // Overlay dB scale on left side
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(dbLabels.enumerated()), id: \.offset) { index, label in
                        Text(label)
                            .font(.system(size: 6, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.6))
                            .frame(height: height / 4.0, alignment: .center)
                    }
                }
                .padding(.leading, 2)
                Spacer()
            }
            .allowsHitTesting(false)
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(red: 0.2, green: 0.2, blue: 0.25), lineWidth: 1)
        )
    }
    
    private var professionalGrid: some View {
        GeometryReader { geometry in
            ZStack {
                // Vertical lines (frequency band separators) - more visible
                ForEach(0..<11, id: \.self) { i in
                    Rectangle()
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .frame(width: 1)
                        .offset(x: CGFloat(i) * (geometry.size.width / 10.0) - geometry.size.width / 2)
                }
                
                // Horizontal lines (dB levels) - more detailed
                ForEach(0..<5, id: \.self) { i in
                    let y = CGFloat(i) * (geometry.size.height / 4.0) - geometry.size.height / 2
                    Rectangle()
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .frame(height: 1)
                        .offset(y: y)
                    
                    // Center line (0 dB) - brighter
                    if i == 2 {
                        Rectangle()
                            .fill(Color(red: 0.4, green: 0.4, blue: 0.5))
                            .frame(height: 1)
                            .offset(y: y)
                    }
                }
                
                // Additional fine grid lines for better detail
                ForEach(1..<4, id: \.self) { i in
                    let y = CGFloat(i) * (geometry.size.height / 4.0) - geometry.size.height / 2
                    // Half-way markers
                    Rectangle()
                        .fill(Color(red: 0.12, green: 0.12, blue: 0.15))
                        .frame(height: 0.5)
                        .offset(y: y - geometry.size.height / 8.0)
                }
            }
        }
    }
    
    private func detailedFrequencyBar(index: Int) -> some View {
        GeometryReader { geometry in
            let bandValue = frequencyBands.indices.contains(index) ? frequencyBands[index] : 0.0
            let normalizedValue = min(1.0, max(0.0, bandValue)) // Clamp 0-1
            let barHeight = CGFloat(normalizedValue) * geometry.size.height
            
            ZStack(alignment: .bottom) {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.08),
                        Color(red: 0.08, green: 0.08, blue: 0.12)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: geometry.size.width / 10.0, height: geometry.size.height)
                
                // Frequency bar with professional multi-color gradient
                if barHeight > 0.5 {
                    VStack(spacing: 0) {
                        // Top section - bright green (high energy)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.0, green: 1.0, blue: 0.0),
                                        Color(red: 0.0, green: 0.9, blue: 0.2)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(2, geometry.size.width / 10.0 - 1), height: max(2, barHeight * 0.25))
                        
                        // Upper middle - medium green
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.0, green: 0.85, blue: 0.3),
                                        Color(red: 0.0, green: 0.75, blue: 0.4)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(2, geometry.size.width / 10.0 - 1), height: max(2, barHeight * 0.3))
                        
                        // Lower middle - darker green
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.0, green: 0.7, blue: 0.5),
                                        Color(red: 0.0, green: 0.6, blue: 0.6)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(2, geometry.size.width / 10.0 - 1), height: max(2, barHeight * 0.3))
                        
                        // Bottom - darkest green
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.0, green: 0.5, blue: 0.7),
                                        Color(red: 0.0, green: 0.4, blue: 0.8)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: max(2, geometry.size.width / 10.0 - 1), height: max(2, barHeight * 0.15))
                    }
                    .frame(height: max(1, barHeight))
                    .animation(.linear(duration: 0.03), value: bandValue)
                } else if barHeight > 0 {
                    // Low energy - single color
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.0, green: 0.6, blue: 0.4),
                                    Color(red: 0.0, green: 0.5, blue: 0.5)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: max(1, geometry.size.width / 10.0 - 1), height: max(1, barHeight))
                        .animation(.linear(duration: 0.03), value: bandValue)
                }
                
                // Peak indicator (white dot at peak)
                if normalizedValue > 0.9 {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3)
                        .offset(y: -barHeight + 2)
                }
            }
        }
    }
    
}
