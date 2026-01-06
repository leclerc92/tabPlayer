//
//  MetronomeView.swift
//  TabPlayer
//
//  Created by claude on 06/01/2026.
//

import SwiftUI
internal import Combine

// MARK: - ViewModel
class MetronomeViewModel: ObservableObject {
    @Published var tempo: Int = MetronomeSettings.defaultTempo
    @Published var isPlaying: Bool = false
    @Published var currentBeat: Int = 0

    private let engine = MetronomeEngine()

    init() {
        // Restaurer le dernier tempo utilisé
        if let savedTempo = UserDefaults.standard.object(forKey: "metronome.tempo") as? Int {
            tempo = MetronomeSettings.clampTempo(savedTempo)
        }

        // Écouter les changements de beat pour l'animation
        engine.onBeatChange = { [weak self] beat in
            self?.currentBeat = beat
        }
    }

    // MARK: - Public Methods

    func togglePlayPause() {
        if isPlaying {
            stop()
        } else {
            start()
        }
    }

    func start() {
        engine.start(tempo: tempo)
        isPlaying = true
    }

    func stop() {
        engine.stop()
        isPlaying = false
        currentBeat = 0
    }

    func incrementTempo(_ value: Int) {
        setTempo(tempo + value)
    }

    func setTempo(_ value: Int) {
        tempo = MetronomeSettings.clampTempo(value)
        saveTempo()

        // Mettre à jour le moteur si en cours de lecture
        if isPlaying {
            engine.setTempo(tempo)
        }
    }

    private func saveTempo() {
        UserDefaults.standard.set(tempo, forKey: "metronome.tempo")
    }
}

// MARK: - Main View
struct MetronomeView: View {
    @StateObject private var viewModel = MetronomeViewModel()

    var body: some View {
        HStack(spacing: 12) {
            // Icône et titre
            HStack(spacing: 6) {
                Image(systemName: "metronome")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Métronome")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Contrôles de tempo
            tempoControl

            // Indicateur visuel (4 temps)
            beatIndicator

            // Bouton Play/Pause
            playPauseButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 5)
    }

    // MARK: - Tempo Control
    private var tempoControl: some View {
        HStack(spacing: 6) {
            // Stepper -10
            Button(action: { viewModel.incrementTempo(-10) }) {
                Image(systemName: "minus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
            .help("Diminuer de 10 BPM")

            // Champ tempo avec steppers fins
            tempoEditor

            // Stepper +10
            Button(action: { viewModel.incrementTempo(10) }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.bordered)
            .help("Augmenter de 10 BPM")
        }
    }

    // MARK: - Tempo Editor
    private var tempoEditor: some View {
        VStack(spacing: 3) {
            // Champ principal
            HStack(spacing: 4) {
                // Stepper -1
                Button(action: { viewModel.incrementTempo(-1) }) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 18, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                // TextField
                TempoTextField(tempo: $viewModel.tempo, onCommit: { viewModel.setTempo($0) })

                // Stepper +1
                Button(action: { viewModel.incrementTempo(1) }) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .frame(width: 18, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            // Label BPM
            Text("BPM")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Beat Indicator
    private var beatIndicator: some View {
        HStack(spacing: 5) {
            ForEach(1...4, id: \.self) { beat in
                Circle()
                    .fill(viewModel.currentBeat == beat ? Color.orange : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.currentBeat == beat ? .orange : .clear, radius: 3)
            }
        }
        .animation(.easeInOut(duration: 0.1), value: viewModel.currentBeat)
    }

    // MARK: - Play/Pause Button
    private var playPauseButton: some View {
        Button(action: viewModel.togglePlayPause) {
            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 36, height: 28)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.isPlaying ? .orange : .accentColor)
        .help(viewModel.isPlaying ? "Arrêter" : "Démarrer")
    }
}

// MARK: - Tempo TextField
struct TempoTextField: View {
    @Binding var tempo: Int
    let onCommit: (Int) -> Void

    @State private var editText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("120", text: $editText)
            .focused($isFocused)
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .frame(width: 50)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFocused ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            .onSubmit { commitEdit() }
            .onChange(of: isFocused) { _, focused in
                if !focused {
                    commitEdit()
                }
            }
            .onChange(of: tempo) { _, newValue in
                if !isFocused {
                    editText = "\(newValue)"
                }
            }
            .onAppear {
                editText = "\(tempo)"
            }
    }

    private func commitEdit() {
        if let value = Int(editText.trimmingCharacters(in: .whitespaces)) {
            let clamped = MetronomeSettings.clampTempo(value)
            onCommit(clamped)
            editText = "\(clamped)"
        } else {
            editText = "\(tempo)"
        }
    }
}

// MARK: - Preview
#Preview {
    MetronomeView()
        .frame(width: 600)
        .padding()
}
