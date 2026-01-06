//
//  SongCreationService.swift
//  TabPlayer
//
//  Created by Claude Code
//

import Foundation

enum SongCreationError: LocalizedError {
    case folderAlreadyExists
    case invalidPath
    case fileOperationFailed(String)
    case invalidFileName

    var errorDescription: String? {
        switch self {
        case .folderAlreadyExists:
            return "Un morceau avec ce nom existe déjà pour cet artiste"
        case .invalidPath:
            return "Le chemin spécifié est invalide"
        case .fileOperationFailed(let reason):
            return "Erreur lors de la création du morceau: \(reason)"
        case .invalidFileName:
            return "Le nom du morceau contient des caractères invalides"
        }
    }
}

class SongCreationService {
    static let shared = SongCreationService()
    private let fileManager = FileManager.default

    private init() {}

    /// Crée un nouveau morceau avec les fichiers spécifiés
    /// - Parameters:
    ///   - artistName: Nom de l'artiste
    ///   - songTitle: Titre du morceau
    ///   - files: Fichiers à copier (PDF, MP4, MOV)
    ///   - rootPath: Chemin racine de la bibliothèque
    /// - Returns: URL du dossier créé
    /// - Throws: SongCreationError si la création échoue
    func createSong(
        artistName: String,
        songTitle: String,
        files: [URL],
        rootPath: String
    ) throws -> URL {
        // Valider le nom du morceau (pas de caractères interdits dans les noms de fichiers)
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?*|\"<>")
        if songTitle.rangeOfCharacter(from: invalidCharacters) != nil {
            throw SongCreationError.invalidFileName
        }

        // Construire le chemin du dossier artiste
        let artistFolderURL = URL(fileURLWithPath: rootPath).appendingPathComponent(artistName)

        // Créer le dossier de l'artiste s'il n'existe pas
        if !fileManager.fileExists(atPath: artistFolderURL.path) {
            do {
                try fileManager.createDirectory(at: artistFolderURL, withIntermediateDirectories: true)
            } catch {
                throw SongCreationError.fileOperationFailed("Impossible de créer le dossier de l'artiste: \(error.localizedDescription)")
            }
        }

        // Construire le chemin du dossier du morceau
        let songFolderURL = artistFolderURL.appendingPathComponent(songTitle)

        // Vérifier que le dossier n'existe pas déjà
        if fileManager.fileExists(atPath: songFolderURL.path) {
            throw SongCreationError.folderAlreadyExists
        }

        // Créer le dossier du morceau
        do {
            try fileManager.createDirectory(at: songFolderURL, withIntermediateDirectories: false)
        } catch {
            throw SongCreationError.fileOperationFailed("Impossible de créer le dossier du morceau: \(error.localizedDescription)")
        }

        // Copier et renommer les fichiers
        for fileURL in files {
            let fileExtension = fileURL.pathExtension.lowercased()

            // Déterminer le nouveau nom selon l'extension
            let newFileName: String
            switch fileExtension {
            case "pdf":
                newFileName = "\(songTitle).pdf"
            case "mp4":
                newFileName = "\(songTitle).mp4"
            case "mov":
                newFileName = "\(songTitle).mov"
            default:
                // Ignorer les fichiers avec des extensions non supportées
                continue
            }

            let destinationURL = songFolderURL.appendingPathComponent(newFileName)

            do {
                try fileManager.copyItem(at: fileURL, to: destinationURL)
            } catch {
                // En cas d'erreur, nettoyer le dossier créé
                try? fileManager.removeItem(at: songFolderURL)
                throw SongCreationError.fileOperationFailed("Impossible de copier le fichier \(fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        return songFolderURL
    }
}
