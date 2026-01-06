//
//  AddSongSheet.swift
//  TabPlayer
//
//  Created by Claude Code
//

import SwiftUI
import UniformTypeIdentifiers

struct AddSongSheet: View {
    let artist: Artiste
    let rootPath: String
    let onComplete: (Bool) -> Void

    @State private var songTitle: String = ""
    @State private var selectedFiles: [URL] = []
    @State private var isDropTargeted: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var isCreating: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // En-tête
            HStack {
                Text("Ajouter un morceau")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Text("Artiste: \(artist.name)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Champ de saisie du titre
            VStack(alignment: .leading, spacing: 8) {
                Text("Titre du morceau")
                    .font(.headline)
                TextField("Entrez le titre du morceau", text: $songTitle)
                    .textFieldStyle(.roundedBorder)
            }

            // Zone de sélection de fichiers
            VStack(alignment: .leading, spacing: 8) {
                Text("Fichiers")
                    .font(.headline)

                // Zone de drag & drop
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isDropTargeted ? Color.accentColor : Color.gray.opacity(0.3),
                            style: StrokeStyle(lineWidth: 2, dash: [5])
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isDropTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                        )

                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text("Glissez vos fichiers ici")
                            .font(.headline)

                        Text("ou")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button(action: selectFiles) {
                            Label("Sélectionner des fichiers", systemImage: "folder")
                        }
                        .buttonStyle(.bordered)

                        Text("Formats acceptés: PDF, MP4, MOV")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .frame(height: 200)
                .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                    handleDrop(providers: providers)
                }
            }

            // Liste des fichiers sélectionnés
            if !selectedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Fichiers sélectionnés (\(selectedFiles.count))")
                        .font(.headline)

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(selectedFiles, id: \.self) { file in
                                HStack {
                                    Image(systemName: iconForFile(file))
                                        .foregroundColor(.accentColor)

                                    Text(file.lastPathComponent)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(1)

                                    Spacer()

                                    Button(action: {
                                        selectedFiles.removeAll { $0 == file }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
            }

            Spacer()

            Divider()

            // Boutons d'action
            HStack {
                Button("Annuler") {
                    dismiss()
                    onComplete(false)
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Ajouter") {
                    createSong()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid || isCreating)
            }
        }
        .padding(24)
        .frame(width: 550, height: 650)
        .alert("Erreur", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !songTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedFiles.isEmpty
    }

    // MARK: - Helper Methods

    private func iconForFile(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf":
            return "doc.text"
        case "mp4", "mov":
            return "video"
        default:
            return "doc"
        }
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.pdf, .mpeg4Movie, .quickTimeMovie]
        panel.message = "Sélectionnez les fichiers à ajouter"

        panel.begin { response in
            if response == .OK {
                for url in panel.urls {
                    if !selectedFiles.contains(url) {
                        selectedFiles.append(url)
                    }
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var hasValidFiles = false

        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url, error == nil else { return }

                let ext = url.pathExtension.lowercased()
                if ["pdf", "mp4", "mov"].contains(ext) {
                    DispatchQueue.main.async {
                        if !selectedFiles.contains(url) {
                            selectedFiles.append(url)
                            hasValidFiles = true
                        }
                    }
                }
            }
        }

        return hasValidFiles
    }

    private func createSong() {
        isCreating = true
        errorMessage = nil

        let trimmedTitle = songTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try SongCreationService.shared.createSong(
                artistName: artist.name,
                songTitle: trimmedTitle,
                files: selectedFiles,
                rootPath: rootPath
            )

            // Succès
            dismiss()
            onComplete(true)
        } catch let error as SongCreationError {
            errorMessage = error.errorDescription
            showingError = true
            isCreating = false
        } catch {
            errorMessage = "Une erreur inattendue s'est produite: \(error.localizedDescription)"
            showingError = true
            isCreating = false
        }
    }
}
