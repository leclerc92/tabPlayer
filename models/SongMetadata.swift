//
//  SongMetadata.swift
//  TabPlayer
//
//  Created by claude on 06/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Song Status Enum
enum SongStatus: String, Codable, CaseIterable {
    case enCours = "en_cours"
    case termine = "termine"

    var displayName: String {
        switch self {
        case .enCours: return "En cours"
        case .termine: return "Terminé"
        }
    }

    var icon: String {
        switch self {
        case .enCours: return "music.note.list"
        case .termine: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .enCours: return .orange
        case .termine: return .green
        }
    }
}

// MARK: - Metadata Structure
struct SongMetadata: Codable {
    let version: String
    let songId: UUID
    var status: SongStatus?
    var lastModified: Date
    let createdAt: Date

    static let currentVersion = "1.0"

    init(songId: UUID = UUID(), status: SongStatus? = nil) {
        self.version = Self.currentVersion
        self.songId = songId
        self.status = status
        let now = Date()
        self.lastModified = now
        self.createdAt = now
    }

    mutating func updateStatus(_ newStatus: SongStatus?) {
        self.status = newStatus
        self.lastModified = Date()
    }
}
