//
//  MockData.swift
//  TabPlayer
//
//  Created by clement leclerc on 05/01/2026.
//

import Foundation

struct MockData {
    static let artists: [Artiste] = [
        Artiste(id: UUID(), name: "Artist 1", songs: [
            Song(id: UUID(), title: "song1", pdf: Bundle.main.url(forResource: "pdf", withExtension: "pdf"), video: Bundle.main.url(forResource: "video", withExtension: "mp4")),
            Song(id: UUID(), title: "song2", pdf: Bundle.main.url(forResource: "pdf2", withExtension: "pdf"), video: nil),
        ]),
        Artiste(id: UUID(), name: "Artist 2", songs: [
            Song(id: UUID(), title: "song1", pdf: nil, video: nil),
            Song(id: UUID(), title: "song2", pdf: nil, video: nil),
        ]),
 
        ]
}

