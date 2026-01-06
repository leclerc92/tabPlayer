//
//  MetronomeEngine.swift
//  TabPlayer
//
//  Created by claude on 06/01/2026.
//

import Foundation
import AVFoundation

/// Engine audio pour le métronome utilisant AVAudioEngine pour une précision maximale
class MetronomeEngine {

    // MARK: - Properties
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    private var timer: DispatchSourceTimer?
    private var currentBeat: Int = 0
    private var tempo: Int = 120

    // Buffers audio pré-générés
    private var accentBuffer: AVAudioPCMBuffer?
    private var normalBuffer: AVAudioPCMBuffer?

    var onBeatChange: ((Int) -> Void)?  // Callback pour l'UI (indicateur visuel)

    // MARK: - Initialization
    init() {
        setupAudioEngine()
        generateClickBuffers()
    }

    deinit {
        stop()
        engine.stop()
    }

    // MARK: - Public Methods

    /// Démarre le métronome à un tempo donné
    func start(tempo: Int) {
        guard tempo >= 40 && tempo <= 240 else { return }

        self.tempo = tempo
        currentBeat = 0

        // Démarrer l'audio engine si nécessaire
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Erreur lors du démarrage de l'audio engine: \(error)")
                return
            }
        }

        // Calculer l'intervalle en nanosecondes
        let interval = 60.0 / Double(tempo)  // secondes par battement
        let intervalNs = UInt64(interval * 1_000_000_000)

        // Créer un timer haute précision
        let queue = DispatchQueue(label: "com.tabplayer.metronome", qos: .userInteractive)
        timer = DispatchSource.makeTimerSource(queue: queue)

        timer?.schedule(deadline: .now(), repeating: .nanoseconds(Int(intervalNs)), leeway: .milliseconds(1))
        timer?.setEventHandler { [weak self] in
            self?.tick()
        }

        timer?.resume()

        // Jouer le premier clic immédiatement
        tick()
    }

    /// Arrête le métronome
    func stop() {
        timer?.cancel()
        timer = nil
        playerNode.stop()
        currentBeat = 0

        DispatchQueue.main.async { [weak self] in
            self?.onBeatChange?(0)
        }
    }

    /// Change le tempo pendant que le métronome joue
    func setTempo(_ bpm: Int) {
        guard bpm >= 40 && bpm <= 240 else { return }

        let wasPlaying = timer != nil
        if wasPlaying {
            stop()
            start(tempo: bpm)
        }
    }

    /// Définit le volume (0.0 - 1.0)
    func setVolume(_ volume: Float) {
        playerNode.volume = max(0.0, min(1.0, volume))
    }

    // MARK: - Private Methods

    private func setupAudioEngine() {
        // Attacher le player node à l'engine
        engine.attach(playerNode)

        // Connecter au mixer principal
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)

        // Volume par défaut
        playerNode.volume = 0.7

        // Préparer l'engine
        engine.prepare()
    }

    private func generateClickBuffers() {
        let sampleRate = 44100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // Clic accentué (premier temps) - 1000 Hz
        accentBuffer = generateClickBuffer(frequency: 1000, duration: 0.05, format: format, amplitude: 0.8)

        // Clic normal - 800 Hz
        normalBuffer = generateClickBuffer(frequency: 800, duration: 0.05, format: format, amplitude: 0.5)
    }

    private func generateClickBuffer(frequency: Double, duration: Double, format: AVAudioFormat, amplitude: Float) -> AVAudioPCMBuffer? {
        let frameCount = UInt32(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount

        guard let channelData = buffer.floatChannelData else { return nil }
        let samples = channelData[0]

        // Générer une onde sinusoïdale avec enveloppe
        for i in 0..<Int(frameCount) {
            let time = Double(i) / format.sampleRate
            let sineWave = sin(2.0 * .pi * frequency * time)

            // Enveloppe (fade out rapide pour éviter les clics)
            let envelope = Float(max(0, 1.0 - (time / duration)))

            samples[i] = Float(sineWave) * amplitude * envelope
        }

        return buffer
    }

    private func tick() {
        currentBeat += 1
        if currentBeat > 4 {
            currentBeat = 1
        }

        // Jouer le son approprié (accent sur le premier temps)
        let buffer = (currentBeat == 1) ? accentBuffer : normalBuffer

        if let buffer = buffer {
            playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)

            if !playerNode.isPlaying {
                playerNode.play()
            }
        }

        // Notifier l'UI sur le main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onBeatChange?(self.currentBeat)
        }
    }
}
