//
//  MetronomeSettings.swift
//  TabPlayer
//
//  Created by claude on 06/01/2026.
//

import Foundation

/// Configuration du métronome
struct MetronomeSettings {
    /// Tempo en battements par minute (BPM)
    var tempo: Int

    /// Volume du métronome (0.0 - 1.0)
    var volume: Float

    /// Valeurs par défaut
    static let defaultTempo = 120
    static let minTempo = 40
    static let maxTempo = 240
    static let defaultVolume: Float = 0.7

    /// Validation du tempo
    static func clampTempo(_ value: Int) -> Int {
        return max(minTempo, min(maxTempo, value))
    }

    /// Validation du volume
    static func clampVolume(_ value: Float) -> Float {
        return max(0.0, min(1.0, value))
    }
}
