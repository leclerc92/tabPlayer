//
//  ContentView.swift
//  TabPlayer
//
//  Created by clement leclerc on 05/01/2026.
//

import SwiftUI
import AVKit

struct ContentView: View {
    
    @AppStorage("rootFolderURL") var rootFolderURL: String?
    @State private var selectedSong: Song? = nil
    @State private var artistes: [Artiste] = []
    @State private var expandedArtists: Set<UUID> = []
    @State private var searchText: String = ""
    
    var filteredArtistes: [Artiste] {
        if searchText.isEmpty {
            return artistes
        }
        return artistes.compactMap { artist in
            let matchingSongs = artist.songs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
            let artistMatches = artist.name.localizedCaseInsensitiveContains(searchText)
            
            if artistMatches {
                return artist // Retourne l'artiste complet si son nom matche
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
        .onAppear {
            if let path = rootFolderURL {
                artistes = scanLibrary(rootPath: path)
            }
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
        HStack {
            Text("Bibliothèque")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            Spacer()
            
            Text("\(artistes.flatMap(\.songs).count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
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
                    }
                } header: {
                    ArtistHeader(artist: artist, songCount: artist.songs.count)
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
                    PDFKitView(url: p)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    func scanLibrary(rootPath: String) -> [Artiste] {
        var artistes: [Artiste] = []
        let fileManager = FileManager.default
        let rootUrl = URL(fileURLWithPath: rootPath)
        
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
                    
                    let song = Song(id: UUID(), title: title, pdf: pdf, video: video)
                    actualArtiste.songs.append(song)
                }
                
                // Trier les chansons par titre
                actualArtiste.songs.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
                
                if !actualArtiste.songs.isEmpty {
                    artistes.append(actualArtiste)
                }
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
        }
        .padding(.vertical, 3)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
