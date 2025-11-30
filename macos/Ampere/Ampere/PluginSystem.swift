//
//  PluginSystem.swift
//  Ampere
//
//  Plugin system for extending Ampere functionality
//

import Foundation
import JavaScriptCore
import Combine

protocol AmperePlugin {
    var name: String { get }
    var version: String { get }
    var author: String { get }
    func initialize(context: PluginContext)
    func execute(command: String, parameters: [String: Any]) -> Any?
}

struct PluginContext {
    let player: AudioPlayer
    let playlist: Playlist
    let equalizer: Equalizer
    let viewModel: PlayerViewModel
}

class PluginManager: ObservableObject {
    @Published var plugins: [AmperePlugin] = []
    private var jsContext: JSContext?
    private let context: PluginContext
    
    init(context: PluginContext) {
        self.context = context
        setupJavaScriptEngine()
    }
    
    private func setupJavaScriptEngine() {
        jsContext = JSContext()
        
        // Expose Ampere API to JavaScript
        jsContext?.setObject(AmpereJSBridge(context: context), forKeyedSubscript: "Ampere" as NSString)
        
        // Add console.log support
        jsContext?.evaluateScript("""
            var console = {
                log: function() {
                    var message = Array.prototype.slice.call(arguments).join(' ');
                    Ampere.log(message);
                }
            };
        """)
    }
    
    func loadPlugin(from url: URL) throws {
        let script = try String(contentsOf: url)
        jsContext?.evaluateScript(script)
    }
    
    func executeScript(_ script: String) -> JSValue? {
        return jsContext?.evaluateScript(script)
    }
    
    func registerPlugin(_ plugin: AmperePlugin) {
        plugins.append(plugin)
        plugin.initialize(context: context)
    }
}

@objc protocol AmpereJSBridgeProtocol: JSExport {
    func play()
    func pause()
    func stop()
    func next()
    func previous()
    func setVolume(_ volume: Double)
    func getVolume() -> Double
    func seek(_ position: Double)
    func getPosition() -> Double
    func getDuration() -> Double
    func loadFile(_ path: String)
    func addToPlaylist(_ path: String)
    func setEQBand(_ band: Int, _ gain: Double)
    func log(_ message: String)
}

class AmpereJSBridge: NSObject, AmpereJSBridgeProtocol {
    private let context: PluginContext
    
    init(context: PluginContext) {
        self.context = context
    }
    
    func play() {
        DispatchQueue.main.async {
            self.context.viewModel.play()
        }
    }
    
    func pause() {
        DispatchQueue.main.async {
            self.context.viewModel.pause()
        }
    }
    
    func stop() {
        DispatchQueue.main.async {
            self.context.viewModel.stop()
        }
    }
    
    func next() {
        DispatchQueue.main.async {
            self.context.viewModel.playNext()
        }
    }
    
    func previous() {
        DispatchQueue.main.async {
            self.context.viewModel.playPrevious()
        }
    }
    
    func setVolume(_ volume: Double) {
        DispatchQueue.main.async {
            self.context.viewModel.setVolume(Float(volume))
        }
    }
    
    func getVolume() -> Double {
        return Double(context.viewModel.volume)
    }
    
    func seek(_ position: Double) {
        DispatchQueue.main.async {
            self.context.viewModel.seek(to: position)
        }
    }
    
    func getPosition() -> Double {
        return context.viewModel.position
    }
    
    func getDuration() -> Double {
        return context.viewModel.duration ?? 0.0
    }
    
    func loadFile(_ path: String) {
        DispatchQueue.main.async {
            self.context.viewModel.loadFile(path: path)
        }
    }
    
    func addToPlaylist(_ path: String) {
        DispatchQueue.main.async {
            self.context.viewModel.addToPlaylist(path: path)
        }
    }
    
    func setEQBand(_ band: Int, _ gain: Double) {
        DispatchQueue.main.async {
            self.context.viewModel.setEQBand(index: band, gain: Float(gain))
        }
    }
    
    func log(_ message: String) {
        print("[Plugin] \(message)")
    }
}

