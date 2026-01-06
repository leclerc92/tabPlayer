//
//  VideoPlayerView.swift
//  TabPlayer
//
//  Created by clement leclerc on 06/01/2026.
//

import SwiftUI
import AVFoundation
import AVKit

struct VideoPlayerView: NSViewRepresentable {
    
    var player: AVPlayer

    func updateNSView(_ NSView: NSView, context: NSViewRepresentableContext<VideoPlayerView>) {
        guard let view = NSView as? AVPlayerView else {
            debugPrint("unexpected view")
            return
        }

        view.player = player
    }

    func makeNSView(context: Context) -> NSView {
        return AVPlayerView(frame: .zero)
    }
}
