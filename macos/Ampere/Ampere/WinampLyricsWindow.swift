//
//  WinampLyricsWindow.swift
//  Ampere
//
//  Lyrics display window
//

import SwiftUI

struct WinampLyricsWindow: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Binding var isPresented: Bool
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Lyrics")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(4)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        dragOffset = .zero
                    }
            )
            
            // Lyrics content
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if let lyrics = viewModel.metadata.lyrics, !lyrics.isEmpty {
                        Text(lyrics)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                            .padding(8)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            Text("No lyrics available")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(20)
                    }
                }
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
        }
        .frame(width: 275, height: 200)
        .background(winampGradient)
        .cornerRadius(4)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .offset(dragOffset)
    }
    
    private var winampGradient: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(red: 0.18, green: 0.18, blue: 0.22), location: 0.0),
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.19), location: 0.5),
                    .init(color: Color(red: 0.12, green: 0.12, blue: 0.16), location: 1.0)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.03),
                            Color.clear,
                            Color.black.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}

