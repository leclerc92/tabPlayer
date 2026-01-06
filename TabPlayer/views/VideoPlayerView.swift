//
//  VideoPlayerView.swift
//  TabPlayer
//
//  Created by clement leclerc on 06/01/2026.
//

import SwiftUI
import AVFoundation
import AVKit
internal import Combine

// MARK: - ViewModel
class PlayerViewModel: ObservableObject {
    @Published var player = AVPlayer()
    @Published var loopStart: Double?
    @Published var loopEnd: Double?
    @Published var isLooping: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupTimeObserver()
        setupLoopValidation()
    }
    
    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
    }
    
    func loadVideo(from url: URL) {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: playerItem)
        
        // Récupérer la durée une fois prêt
        playerItem.publisher(for: \.status)
            .filter { $0 == .readyToPlay }
            .first()
            .sink { [weak self] _ in
                self?.duration = playerItem.duration.seconds
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Capture Points
    func capturePointA() {
        loopStart = currentTime
    }
    
    func capturePointB() {
        let current = currentTime
        if let start = loopStart, current > start {
            loopEnd = current
        } else if loopStart == nil {
            // Si A n'est pas défini, on peut quand même capturer B
            loopEnd = current
        }
    }
    
    // MARK: - Manual Updates
    func updateLoopStart(_ time: Double?) {
        guard let t = time else {
            loopStart = nil
            return
        }
        // Clamp entre 0 et la durée (ou loopEnd si défini)
        let maxValue = loopEnd ?? duration
        loopStart = max(0, min(t, maxValue - 0.1))
    }
    
    func updateLoopEnd(_ time: Double?) {
        guard let t = time else {
            loopEnd = nil
            return
        }
        // Clamp entre loopStart (ou 0) et la durée
        let minValue = (loopStart ?? 0) + 0.1
        loopEnd = max(minValue, min(t, duration))
    }
    
    func clearLoop() {
        loopStart = nil
        loopEnd = nil
        isLooping = false
    }
    
    func seekToStart() {
        guard let start = loopStart else { return }
        player.seek(to: CMTime(seconds: start, preferredTimescale: 600),
                    toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    func togglePlayPause() {
        if player.rate > 0 {
            player.pause()
        } else {
            player.play()
        }
    }
    
    // MARK: - Private
    private func setupLoopValidation() {
        // Validation automatique de l'état de boucle
        Publishers.CombineLatest($loopStart, $loopEnd)
            .map { start, end in
                guard let s = start, let e = end else { return false }
                return s < e
            }
            .assign(to: &$isLooping)
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.03, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            self.currentTime = time.seconds
            
            // Gestion de la boucle
            if self.isLooping,
               let start = self.loopStart,
               let end = self.loopEnd,
               time.seconds >= end {
                self.player.seek(to: CMTime(seconds: start, preferredTimescale: 600),
                                 toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }
}

// MARK: - Vue Principale
struct VideoPlayerView: View {
    var url: URL
    @StateObject private var viewModel = PlayerViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VideoPlayerNSView(player: viewModel.player)
                .onAppear { viewModel.loadVideo(from: url) }
                .onChange(of: url) { _, _ in viewModel.loadVideo(from: url) }
            
            VStack(spacing: 12) {
                // Barre de progression avec zone de boucle
                LoopProgressBar(
                    currentTime: viewModel.currentTime,
                    duration: viewModel.duration,
                    loopStart: viewModel.loopStart,
                    loopEnd: viewModel.loopEnd
                )
                .frame(height: 8)
                .padding(.horizontal, 20)
                
                // Contrôles de boucle
                loopControls
            }
            .padding(.bottom, 50)
        }
    }
    
    var loopControls: some View {
        HStack(spacing: 12) {
            // Point A
            LoopPointControl(
                label: "A",
                time: Binding(
                    get: { viewModel.loopStart },
                    set: { viewModel.updateLoopStart($0) }
                ),
                isActive: viewModel.loopStart != nil,
                duration: viewModel.duration,
                onCapture: viewModel.capturePointA
            )
            
            // Boutons centraux
            VStack(spacing: 8) {
                // Retour au début de boucle
                Button(action: viewModel.seekToStart) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.isLooping)
                
                // Indicateur état boucle
                HStack(spacing: 4) {
                    Image(systemName: viewModel.isLooping ? "repeat" : "repeat")
                        .font(.system(size: 10))
                    Text(viewModel.isLooping ? "ON" : "OFF")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(viewModel.isLooping ? .orange : .secondary)
            }
            
            // Point B
            LoopPointControl(
                label: "B",
                time: Binding(
                    get: { viewModel.loopEnd },
                    set: { viewModel.updateLoopEnd($0) }
                ),
                isActive: viewModel.loopEnd != nil,
                duration: viewModel.duration,
                onCapture: viewModel.capturePointB
            )
            
            // Reset
            if viewModel.loopStart != nil || viewModel.loopEnd != nil {
                Button(action: viewModel.clearLoop) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLooping)
    }
}

// MARK: - LoopPointControl (Contrôle pour A ou B)
struct LoopPointControl: View {
    let label: String
    @Binding var time: Double?
    let isActive: Bool
    let duration: Double
    let onCapture: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            // Bouton capture
            Button(action: onCapture) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 36, height: 28)
            }
            .buttonStyle(.borderedProminent)
            .tint(isActive ? .orange : .gray.opacity(0.6))
            
            // Éditeur de temps
            TimeEditor(
                time: $time,
                duration: duration
            )
        }
        .padding(8)
        .background(Color.black.opacity(0.2))
        .cornerRadius(10)
    }
}

// MARK: - TimeEditor (Champ éditable avec steppers)
struct TimeEditor: View {
    @Binding var time: Double?
    let duration: Double
    
    @State private var editText: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isFocused: Bool
    
    // Pas d'incrémentation
    private let fineStep: Double = 0.1    // 100ms
    private let coarseStep: Double = 1.0  // 1s
    
    var body: some View {
        VStack(spacing: 4) {
            // Affichage / Édition du temps
            HStack(spacing: 2) {
                // Stepper gauche (diminuer)
                Button(action: { adjustTime(-fineStep) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 20)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(time == nil)
                
                // Champ texte
                TextField("--:--", text: $editText)
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(time != nil ? .white : .secondary)
                    .frame(width: 58)
                    .padding(.vertical, 3)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isFocused ? Color.white.opacity(0.15) : Color.black.opacity(0.2))
                    )
                    .onSubmit { commitEdit() }
                    .onChange(of: isFocused) { _, focused in
                        if focused {
                            isEditing = true
                            // Sélectionner tout le texte pour faciliter l'édition
                            if time != nil {
                                editText = formatTimeForEdit(time!)
                            }
                        } else if isEditing {
                            commitEdit()
                            isEditing = false
                        }
                    }
                    .onChange(of: time) { _, newValue in
                        if !isFocused {
                            editText = formatTime(newValue)
                        }
                    }
                    .onAppear {
                        editText = formatTime(time)
                    }
                
                // Stepper droit (augmenter)
                Button(action: { adjustTime(fineStep) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .frame(width: 16, height: 20)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(time == nil)
            }
            
            // Steppers gros pas (±1s)
            HStack(spacing: 16) {
                Button(action: { adjustTime(-coarseStep) }) {
                    Text("-1s")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(time == nil)
                
                Button(action: { adjustTime(coarseStep) }) {
                    Text("+1s")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(time == nil)
            }
        }
    }
    
    private func adjustTime(_ delta: Double) {
        guard let current = time else { return }
        let newValue = max(0, min(current + delta, duration))
        time = newValue
    }
    
    private func commitEdit() {
        if let parsed = parseTime(editText) {
            time = max(0, min(parsed, duration))
        }
        editText = formatTime(time)
    }
    
    private func formatTime(_ seconds: Double?) -> String {
        guard let s = seconds else { return "--:--" }
        let mins = Int(s) / 60
        let secs = Int(s) % 60
        let ms = Int((s.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, ms)
    }
    
    private func formatTimeForEdit(_ seconds: Double) -> String {
        // Format plus simple pour l'édition
        let mins = Int(seconds) / 60
        let secs = seconds.truncatingRemainder(dividingBy: 60)
        if mins > 0 {
            return String(format: "%d:%.1f", mins, secs)
        } else {
            return String(format: "%.1f", secs)
        }
    }
    
    private func parseTime(_ input: String) -> Double? {
        let clean = input.trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: ",", with: ".")
        
        // Format "mm:ss" ou "mm:ss.d"
        if clean.contains(":") {
            let parts = clean.split(separator: ":")
            guard parts.count == 2,
                  let mins = Double(parts[0]),
                  let secs = Double(parts[1]) else { return nil }
            return mins * 60 + secs
        }
        // Format "ss" ou "ss.d" (secondes seules)
        else if let secs = Double(clean) {
            return secs
        }
        
        return nil
    }
}

// MARK: - LoopProgressBar (Visualisation de la boucle)
struct LoopProgressBar: View {
    let currentTime: Double
    let duration: Double
    let loopStart: Double?
    let loopEnd: Double?
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Fond
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.2))
                
                // Zone de boucle
                if let start = loopStart, let end = loopEnd, duration > 0 {
                    let startX = (start / duration) * geo.size.width
                    let endX = (end / duration) * geo.size.width
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.4))
                        .frame(width: endX - startX)
                        .offset(x: startX)
                }
                
                // Marqueurs A et B
                if let start = loopStart, duration > 0 {
                    let x = (start / duration) * geo.size.width
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 2, height: geo.size.height + 4)
                        .offset(x: x - 1)
                }
                
                if let end = loopEnd, duration > 0 {
                    let x = (end / duration) * geo.size.width
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 2, height: geo.size.height + 4)
                        .offset(x: x - 1)
                }
                
                // Position actuelle
                if duration > 0 {
                    let x = (currentTime / duration) * geo.size.width
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .offset(x: x - 5)
                        .shadow(radius: 2)
                }
            }
        }
    }
}

// MARK: - VideoPlayerNSView
struct VideoPlayerNSView: NSViewRepresentable {
    var player: AVPlayer
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView(frame: .zero)
        view.player = player
        view.controlsStyle = .floating
        
        let speedMenu = NSMenu(title: "Vitesse")
        let speeds: [Float] = [0.25,0.4,0.5,0.6,0.75,1.0]
        for speed in speeds {
            let item = NSMenuItem(
                title: speed == 1.0 ? "Normal (1x)" : "×\(speed)",
                action: #selector(Coordinator.changeSpeed(_:)),
                keyEquivalent: ""
            )
            item.target = context.coordinator
            item.representedObject = speed
            if speed == 1.0 { item.state = .on }
            speedMenu.addItem(item)
        }
        view.actionPopUpButtonMenu = speedMenu
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player != player {
            nsView.player = player
        }
    }
    
    class Coordinator: NSObject {
        var parent: VideoPlayerNSView
        init(_ parent: VideoPlayerNSView) { self.parent = parent }
        
        @objc func changeSpeed(_ sender: NSMenuItem) {
            guard let speed = sender.representedObject as? Float else { return }
            parent.player.rate = speed
            sender.menu?.items.forEach { $0.state = ($0 == sender) ? .on : .off }
        }
    }
}

#Preview {
    VideoPlayerView(url: URL(fileURLWithPath: "/path/to/video.mp4"))
        .frame(width: 800, height: 600)
}
