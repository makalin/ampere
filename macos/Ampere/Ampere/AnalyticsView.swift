//
//  AnalyticsView.swift
//  Ampere
//
//  Advanced listening statistics and analytics
//

import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text("Listening Analytics")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(8)
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Overall Statistics
                    statsSection(title: "OVERALL STATISTICS") {
                        VStack(alignment: .leading, spacing: 8) {
                            statRow(label: "Total Tracks Played", value: "\(viewModel.listeningAnalytics.stats.totalTracksPlayed)")
                            statRow(label: "Unique Tracks", value: "\(viewModel.listeningAnalytics.stats.uniqueTracksPlayed)")
                            statRow(label: "Total Listening Time", value: formatTime(viewModel.listeningAnalytics.stats.totalListeningTime))
                            statRow(label: "Total Hours", value: String(format: "%.1f", viewModel.listeningAnalytics.stats.totalListeningHours))
                            statRow(label: "Avg Session Length", value: formatTime(viewModel.listeningAnalytics.stats.averageSessionLength))
                        }
                    }
                    
                    // Top Tracks
                    if !viewModel.listeningAnalytics.stats.topTracks.isEmpty {
                        statsSection(title: "TOP TRACKS") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(viewModel.listeningAnalytics.getTopTracks(limit: 10).enumerated()), id: \.element.path) { index, track in
                                    HStack {
                                        Text("\(index + 1).")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.gray)
                                            .frame(width: 30, alignment: .leading)
                                        Text(URL(fileURLWithPath: track.path).lastPathComponent)
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        Spacer()
                                        Text("\(track.playCount)x")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Top Genres
                    if !viewModel.listeningAnalytics.stats.favoriteGenres.isEmpty {
                        statsSection(title: "TOP GENRES") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.listeningAnalytics.getTopGenres(limit: 5), id: \.0) { genre, count in
                                    HStack {
                                        Text(genre)
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(count)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Top Artists
                    if !viewModel.listeningAnalytics.stats.favoriteArtists.isEmpty {
                        statsSection(title: "TOP ARTISTS") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(viewModel.listeningAnalytics.getTopArtists(limit: 5), id: \.0) { artist, count in
                                    HStack {
                                        Text(artist)
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(count)")
                                            .font(.system(size: 8, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Listening Patterns
                    if !viewModel.listeningAnalytics.stats.listeningByHour.isEmpty {
                        statsSection(title: "LISTENING PATTERNS") {
                            VStack(alignment: .leading, spacing: 4) {
                                let peakHours = viewModel.listeningAnalytics.getListeningPeakHours()
                                if !peakHours.isEmpty {
                                    Text("Peak Hours: \(peakHours.map { "\($0):00" }.joined(separator: ", "))")
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    
                    // Reset Button
                    Button(action: {
                        viewModel.listeningAnalytics.reset()
                    }) {
                        Text("Reset Statistics")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                            .background(Color(red: 0.3, green: 0.1, blue: 0.1))
                            .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
            }
        }
        .frame(width: 400, height: 600)
        .background(winampGradient)
        .cornerRadius(4)
    }
    
    private func statsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            content()
                .padding(8)
                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                .cornerRadius(4)
        }
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 8, design: .monospaced, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var winampGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.18, green: 0.18, blue: 0.22), location: 0.0),
                .init(color: Color(red: 0.12, green: 0.12, blue: 0.16), location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

