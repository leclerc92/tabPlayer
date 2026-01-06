//
//  AddArtistSheet.swift
//  TabPlayer
//
//  Created by Claude Code
//

import SwiftUI

struct AddArtistSheet: View {
    let rootPath: String
    let onComplete: (Bool) -> Void

    @State private var artistName: String = ""
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var isCreating: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // En-tête
            HStack {
                Text("Créer un nouvel artiste")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }

            Divider()

            // Champ de saisie du nom
            VStack(alignment: .leading, spacing: 8) {
                Text("Nom de l'artiste")
                    .font(.headline)
                TextField("Entrez le nom de l'artiste", text: $artistName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        if isFormValid {
                            createArtist()
                        }
                    }

                Text("Un dossier sera créé avec ce nom dans votre bibliothèque.")
                    .font(.caption)
                    .foregroundColor(.secondary)
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

                Button("Créer") {
                    createArtist()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isFormValid || isCreating)
            }
        }
        .padding(24)
        .frame(width: 450, height: 250)
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
        !artistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Helper Methods

    private func createArtist() {
        isCreating = true
        errorMessage = nil

        let trimmedName = artistName.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            _ = try ArtistCreationService.shared.createArtist(
                artistName: trimmedName,
                rootPath: rootPath
            )

            // Succès
            dismiss()
            onComplete(true)
        } catch let error as ArtistCreationError {
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
