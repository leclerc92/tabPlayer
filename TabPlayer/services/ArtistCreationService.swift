//
//  ArtistCreationService.swift
//  TabPlayer
//
//  Created by Claude Code
//

import Foundation

enum ArtistCreationError: LocalizedError {
    case folderAlreadyExists
    case invalidPath
    case fileOperationFailed(String)
    case invalidArtistName

    var errorDescription: String? {
        switch self {
        case .folderAlreadyExists:
            return "Un artiste avec ce nom existe déjà"
        case .invalidPath:
            return "Le chemin spécifié est invalide"
        case .fileOperationFailed(let reason):
            return "Erreur lors de la création de l'artiste: \(reason)"
        case .invalidArtistName:
            return "Le nom de l'artiste contient des caractères invalides"
        }
    }
}

class ArtistCreationService {
    static let shared = ArtistCreationService()
    private let fileManager = FileManager.default

    private init() {}

    /// Crée un nouveau dossier artiste
    /// - Parameters:
    ///   - artistName: Nom de l'artiste
    ///   - rootPath: Chemin racine de la bibliothèque
    /// - Returns: URL du dossier créé
    /// - Throws: ArtistCreationError si la création échoue
    func createArtist(
        artistName: String,
        rootPath: String
    ) throws -> URL {
        // Valider le nom de l'artiste (pas de caractères interdits dans les noms de fichiers)
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?*|\"<>")
        if artistName.rangeOfCharacter(from: invalidCharacters) != nil {
            throw ArtistCreationError.invalidArtistName
        }

        // Construire le chemin du dossier artiste
        let artistFolderURL = URL(fileURLWithPath: rootPath).appendingPathComponent(artistName)

        // Vérifier que le dossier n'existe pas déjà
        if fileManager.fileExists(atPath: artistFolderURL.path) {
            throw ArtistCreationError.folderAlreadyExists
        }

        // Créer le dossier de l'artiste
        do {
            try fileManager.createDirectory(at: artistFolderURL, withIntermediateDirectories: false)
        } catch {
            throw ArtistCreationError.fileOperationFailed("Impossible de créer le dossier de l'artiste: \(error.localizedDescription)")
        }

        return artistFolderURL
    }
}
