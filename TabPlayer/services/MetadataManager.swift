//
//  MetadataManager.swift
//  TabPlayer
//
//  Created by claude on 06/01/2026.
//

import Foundation

class MetadataManager {
    static let shared = MetadataManager()
    private let metadataFileName = ".metadata.json"
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Load Metadata
    func loadMetadata(from songFolderURL: URL) -> SongMetadata {
        let metadataURL = songFolderURL.appendingPathComponent(metadataFileName)

        // Try to load existing metadata
        if fileManager.fileExists(atPath: metadataURL.path) {
            do {
                let data = try Data(contentsOf: metadataURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                if let metadata = try? decoder.decode(SongMetadata.self, from: data) {
                    // Validate version compatibility
                    if metadata.version == SongMetadata.currentVersion {
                        return metadata
                    } else {
                        // Migration logic would go here
                        print("Metadata version mismatch at \(songFolderURL.lastPathComponent), recreating")
                    }
                } else {
                    print("Corrupted metadata at \(songFolderURL.lastPathComponent), recreating")
                }

                // Backup corrupted file
                let backupURL = metadataURL.appendingPathExtension("backup")
                try? fileManager.copyItem(at: metadataURL, to: backupURL)
            } catch {
                print("Error reading metadata: \(error)")
            }
        }

        // Create new metadata if doesn't exist or failed to load
        let newMetadata = SongMetadata()
        saveMetadata(newMetadata, to: songFolderURL)
        return newMetadata
    }

    // MARK: - Save Metadata
    @discardableResult
    func saveMetadata(_ metadata: SongMetadata, to songFolderURL: URL) -> Bool {
        let metadataURL = songFolderURL.appendingPathComponent(metadataFileName)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(metadata)
            try data.write(to: metadataURL, options: .atomic)
            return true
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain {
                switch error.code {
                case NSFileWriteNoPermissionError:
                    print("Permission denied writing to \(metadataURL.path)")
                case NSFileWriteOutOfSpaceError:
                    print("Disk full, cannot write metadata")
                default:
                    print("Error saving metadata: \(error.localizedDescription)")
                }
            }
            return false
        }
    }

    // MARK: - Update Song Status
    func updateSongStatus(_ song: Song, newStatus: SongStatus?) -> Bool {
        var metadata = loadMetadata(from: song.folderURL)
        metadata.updateStatus(newStatus)
        return saveMetadata(metadata, to: song.folderURL)
    }
}
