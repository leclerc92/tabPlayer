//
//  ContentView.swift
//  TabPlayer
//
//  Created by clement leclerc on 05/01/2026.
//

import SwiftUI
import AVKit

enum FilterType: String, CaseIterable {
    case all = "Tout"
    case enCours = "En cours"
    case termine = "Terminé"

    var icon: String {
        switch self {
        case .all: return "music.note.list"
        case .enCours: return "music.note.list"
        case .termine: return "checkmark.circle.fill"
        }
    }
}

struct ContentView: View {

    @AppStorage("rootFolderURL") var rootFolderURL: String?
    @State private var selectedSong: Song? = nil
    @State private var artistes: [Artiste] = []
    @State private var expandedArtists: Set<UUID> = []
    @State private var searchText: String = ""
    @State private var selectedFilter: FilterType = .all
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isScanning = false
    @State private var selectedArtistForNewSong: Artiste?
    @State private var showingAddArtistSheet = false

    var filteredArtistes: [Artiste] {
        var artists = artistes

        // Apply status filter first
        if selectedFilter != .all {
            artists = artists.compactMap { artist in
                let filteredSongs = artist.songs.filter { song in
                    switch selectedFilter {
                    case .all:
                        return true
                    case .enCours:
                        return song.status == .enCours
                    case .termine:
                        return song.status == .termine
                    }
                }

                if filteredSongs.isEmpty {
                    return nil
                }
                return Artiste(id: artist.id, name: artist.name, songs: filteredSongs)
            }
        }

        // Apply search filter
        if searchText.isEmpty {
            return artists
        }

        return artists.compactMap { artist in
            let matchingSongs = artist.songs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
            let artistMatches = artist.name.localizedCaseInsensitiveContains(searchText)

            if artistMatches {
                return artist
            } else if !matchingSongs.isEmpty {
                return Artiste(id: artist.id, name: artist.name, songs: matchingSongs)
            }
            return nil
        }
    }
    
    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 350)
        } detail: {
            detailView
        }
        .sheet(item: $selectedArtistForNewSong) { artist in
            AddSongSheet(
                artist: artist,
                rootPath: rootFolderURL ?? "",
                onComplete: { success in
                    if success {
                        if let path = rootFolderURL {
                            artistes = scanLibrary(rootPath: path)
                        }
                    }
                    selectedArtistForNewSong = nil
                }
            )
        }
        .sheet(isPresented: $showingAddArtistSheet) {
            AddArtistSheet(
                rootPath: rootFolderURL ?? "",
                onComplete: { success in
                    if success {
                        if let path = rootFolderURL {
                            artistes = scanLibrary(rootPath: path)
                        }
                    }
                    showingAddArtistSheet = false
                }
            )
        }
        .onAppear {
            if let path = rootFolderURL {
                artistes = scanLibrary(rootPath: path)
            }
        }
        .alert("Erreur", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Sidebar
    var sidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            sidebarList
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Rechercher")
        .background(.ultraThinMaterial)
    }
    
    private var sidebarHeader: some View {
        VStack(spacing: 8) {
            // Title and count
            HStack {
                Text("Bibliothèque")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Text("\(filteredArtistes.flatMap(\.songs).count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()

                // Add artist button
                Button(action: {
                    showingAddArtistSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.plain)
                .help("Créer un nouvel artiste")

                // Refresh button
                Button(action: rescanLibrary) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isScanning ? .secondary : .primary)
                        .rotationEffect(.degrees(isScanning ? 360 : 0))
                        .animation(isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isScanning)
                }
                .buttonStyle(.plain)
                .disabled(isScanning)
                .help("Actualiser la bibliothèque")
            }

            // Filter buttons
            HStack(spacing: 6) {
                ForEach(FilterType.allCases, id: \.self) { filter in
                    Button(action: { selectedFilter = filter }) {
                        HStack(spacing: 4) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 9))
                            Text(filter.rawValue)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            selectedFilter == filter ?
                                Color.accentColor.opacity(0.15) :
                                Color.clear
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    selectedFilter == filter ?
                                        Color.accentColor :
                                        Color.secondary.opacity(0.2),
                                    lineWidth: 1
                                )
                        )
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
    
    private var sidebarList: some View {
        List(selection: $selectedSong) {
            ForEach(filteredArtistes) { artist in
                Section(isExpanded: binding(for: artist.id)) {
                    ForEach(artist.songs) { song in
                        SongRow(song: song, isSelected: selectedSong?.id == song.id)
                            .tag(song)
                            .contextMenu {
                                statusContextMenu(for: song)
                            }
                    }
                } header: {
                    ArtistHeader(artist: artist, songCount: artist.songs.count)
                        .contentShape(Rectangle())
                        .contextMenu {
                            Button(action: {
                                selectedArtistForNewSong = artist
                            }) {
                                Label("Ajouter un morceau", systemImage: "plus.circle")
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Detail View
    var detailView: some View {
        HSplitView {
            if let song = selectedSong {
                if let p = song.pdf {
                    VStack(spacing: 0) {
                        PDFKitView(url: p)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        MetronomeView()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial)
                    }
                }
                if let v = song.video {
                    VideoPlayerView(url: v)
                }
            } else {
                emptyState
            }
        }
        .id(selectedSong?.id)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.tertiary)
            
            Text("Aucune chanson sélectionnée")
                .font(.title3)
                .foregroundStyle(.secondary)
            
            Text("Sélectionnez une chanson dans la liste")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helpers
    private func binding(for artistId: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedArtists.contains(artistId) },
            set: { isExpanded in
                if isExpanded {
                    expandedArtists.insert(artistId)
                } else {
                    expandedArtists.remove(artistId)
                }
            }
        )
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func statusContextMenu(for song: Song) -> some View {
        Button {
            updateSongStatus(song, newStatus: nil)
        } label: {
            Label("Aucun statut", systemImage: "minus.circle")
        }

        Divider()

        ForEach([SongStatus.enCours, SongStatus.termine], id: \.self) { status in
            Button {
                updateSongStatus(song, newStatus: status)
            } label: {
                Label(status.displayName, systemImage: status.icon)
            }
        }

        Divider()

        Button {
            showInFinder(song)
        } label: {
            Label("Afficher dans le Finder", systemImage: "folder")
        }
    }

    private func updateSongStatus(_ song: Song, newStatus: SongStatus?) {
        // Update in metadata
        let success = MetadataManager.shared.updateSongStatus(song, newStatus: newStatus)

        guard success else {
            errorMessage = "Impossible de sauvegarder le statut pour '\(song.title)'. Vérifiez les permissions du dossier."
            showErrorAlert = true
            return
        }

        // Rescan library to refresh UI
        if let path = rootFolderURL {
            artistes = scanLibrary(rootPath: path)
        }
    }

    private func showInFinder(_ song: Song) {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: song.folderURL.path)
    }

    private func rescanLibrary() {
        guard let path = rootFolderURL else { return }

        isScanning = true

        // Use a slight delay to allow the animation to start
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            artistes = scanLibrary(rootPath: path)
            isScanning = false
        }
    }

    func scanLibrary(rootPath: String) -> [Artiste] {
        var artistes: [Artiste] = []
        let fileManager = FileManager.default
        let rootUrl = URL(fileURLWithPath: rootPath)
        let metadataManager = MetadataManager.shared

        do {
            let artistesFolders = try fileManager.contentsOfDirectory(at: rootUrl, includingPropertiesForKeys: nil)

            for artisteFolder in artistesFolders {
                guard artisteFolder.hasDirectoryPath else { continue }

                var actualArtiste = Artiste(
                    id: UUID(),
                    name: artisteFolder.lastPathComponent,
                    songs: []
                )

                let songsFolders = try fileManager.contentsOfDirectory(
                    at: artisteFolder,
                    includingPropertiesForKeys: nil
                )

                for songFolder in songsFolders {
                    guard songFolder.hasDirectoryPath else { continue }

                    let files = try fileManager.contentsOfDirectory(
                        at: songFolder,
                        includingPropertiesForKeys: nil,
                        options: .skipsHiddenFiles
                    )

                    let title = songFolder.lastPathComponent
                    let pdf = files.first { $0.pathExtension == "pdf" }
                    let video = files.first { ["mp4", "mov", "m4v"].contains($0.pathExtension.lowercased()) }

                    // Load metadata for stable ID and status
                    let metadata = metadataManager.loadMetadata(from: songFolder)

                    let song = Song(
                        id: metadata.songId,
                        title: title,
                        pdf: pdf,
                        video: video,
                        status: metadata.status,
                        folderURL: songFolder
                    )
                    actualArtiste.songs.append(song)
                }
                
                // Trier les chansons par titre
                actualArtiste.songs.sort { $0.title.localizedCompare($1.title) == .orderedAscending }

                // Ajouter l'artiste même s'il n'a pas de morceaux
                artistes.append(actualArtiste)
            }
            
            // Trier les artistes par nom
            artistes.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
            
        } catch {
            print("Erreur lors du scan: \(error.localizedDescription)")
        }
        
        return artistes
    }
}

// MARK: - Artist Header
struct ArtistHeader: View {
    let artist: Artiste
    let songCount: Int
    
    var body: some View {
        HStack(spacing: 8) {
            // Icône artiste
            ZStack {
                Circle()
                    .fill(artistColor.gradient)
                    .frame(width: 24, height: 24)
                
                Text(artist.name.prefix(1).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(artist.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(songCount)")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
    }
    
    // Couleur basée sur le nom de l'artiste (consistante)
    var artistColor: Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .teal, .indigo, .mint, .cyan]
        let hash = abs(artist.name.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Song Row
struct SongRow: View {
    let song: Song
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Indicateurs de contenu
            HStack(spacing: 4) {
                if song.pdf != nil {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .orange)
                }
                if song.video != nil {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .blue)
                }
            }
            .frame(width: 28, alignment: .leading)

            // Titre
            Text(song.title)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? .white : .primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            // Status badge
            if let status = song.status {
                Image(systemName: status.icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : status.color)
            }
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
