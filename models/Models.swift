//
//  Models.swift
//  TabPlayer
//
//  Created by clement leclerc on 05/01/2026.
//

import Foundation

struct Artiste: Identifiable {
    var id: UUID
    var name: String
    var songs: [Song]
}


struct Song: Identifiable {
    var id: UUID
    var title: String
    var pdf: URL?
    var video: URL?
}
