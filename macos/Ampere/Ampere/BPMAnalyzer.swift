//
//  BPMAnalyzer.swift
//  Ampere
//
//  Rough tempo estimate from PCM (when tags have no BPM). For DJ-grade accuracy use dedicated libs.
//

import Foundation
import AVFoundation

enum BPMAnalyzer {

    /// Estimates BPM by autocorrelating a short-time energy envelope (~first 45s). Runs off the main thread; calls back on main.
    static func estimateBPM(fileURL: URL, completion: @escaping (Double?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let bpm = syncEstimate(url: fileURL)
            DispatchQueue.main.async {
                completion(bpm)
            }
        }
    }

    private static func syncEstimate(url: URL) -> Double? {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let sr = format.sampleRate
            guard sr > 0, format.channelCount >= 1 else { return nil }

            let maxFrames = AVAudioFrameCount(min(UInt64(file.length), UInt64(sr * 45)))
            guard maxFrames > 4096 else { return nil }

            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: maxFrames) else { return nil }
            try file.read(into: buffer, frameCount: maxFrames)
            let frameCount = Int(buffer.frameLength)

            let hop = 512
            var mono = [Float](repeating: 0, count: frameCount)

            switch format.commonFormat {
            case .pcmFormatFloat32:
                guard let ch = buffer.floatChannelData else { return nil }
                if format.channelCount == 1 {
                    mono = Array(UnsafeBufferPointer(start: ch[0], count: frameCount))
                } else {
                    let l = ch[0], r = ch[1]
                    for i in 0..<frameCount { mono[i] = (l[i] + r[i]) * 0.5 }
                }
            case .pcmFormatInt16:
                guard let ch = buffer.int16ChannelData else { return nil }
                let scale: Float = 1.0 / Float(Int16.max)
                if format.channelCount == 1 {
                    let p = ch[0]
                    for i in 0..<frameCount { mono[i] = Float(p[i]) * scale }
                } else {
                    let l = ch[0], r = ch[1]
                    for i in 0..<frameCount { mono[i] = (Float(l[i]) + Float(r[i])) * 0.5 * scale }
                }
            default:
                return nil
            }

            var energies: [Float] = []
            energies.reserveCapacity(frameCount / hop + 1)
            var i = 0
            while i + hop <= frameCount {
                var e: Float = 0
                for j in 0..<hop {
                    let s = mono[i + j]
                    e += s * s
                }
                energies.append(e)
                i += hop
            }
            guard energies.count > 80 else { return nil }

            let mean = energies.reduce(0, +) / Float(energies.count)
            let centered = energies.map { $0 - mean }
            let n = centered.count

            let energySr = sr / Double(hop)
            let minBPM = 72.0
            let maxBPM = 180.0
            let minLag = max(2, Int((60.0 / maxBPM) * energySr))
            let maxLag = min(n / 2 - 1, Int((60.0 / minBPM) * energySr))
            guard minLag < maxLag else { return nil }

            var bestLag = minLag
            var bestCorr: Float = -Float.greatestFiniteMagnitude
            for lag in minLag...maxLag {
                var c: Float = 0
                var k = 0
                while k < n - lag {
                    c += centered[k] * centered[k + lag]
                    k += 1
                }
                if c > bestCorr {
                    bestCorr = c
                    bestLag = lag
                }
            }

            let bpm = 60.0 * energySr / Double(bestLag)
            if bpm.isFinite && bpm >= 55 && bpm <= 210 {
                return bpm
            }
            return nil
        } catch {
            print("BPMAnalyzer: \(error)")
            return nil
        }
    }
}
