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
    @State var selectedSong: Song? = nil
    @State var player: AVPlayer = AVPlayer()
    @State var artistes: [Artiste] = []
    
    var body: some View {
        NavigationSplitView {
            List {
                ForEach(artistes) { artist in
                    DisclosureGroup(artist.name){
                        ForEach(artist.songs){ song in
                            Button(song.title) {
                                selectedSong = song
                                player.pause()
                                if let video = song.video {
                                    let asset = AVURLAsset(url:video)
                                    let playerItem = AVPlayerItem(asset: asset)
                                    player.replaceCurrentItem(with: playerItem)
                                }
                                
                            }
                        }
                    }
                }
            }
        } detail: {
            HSplitView {
                if let song = selectedSong {
                    if let p = song.pdf {
                        PDFKitView(url: p)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    if let v = song.video {
                        VideoPlayerView(player: player)
                    }
                    
                } else {
                    Text(" PDF : pas de son selectionné")
                    Text("video : pas de son selectionné")
                }
                
            }
            .id(selectedSong?.id)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        }.onAppear(){
            if let path = rootFolderURL {
                artistes = scanLibrary(rootPath: path)
            }
        }
        
    }
        

    
    func scanLibrary(rootPath:String) -> [Artiste] {
        
        print("scan library")
        
        var artistes:[Artiste] = []
        let fileManager = FileManager.default
        let roorUrl = URL(fileURLWithPath: rootPath)
        
        //LISTER LES DOSSIER DANS LE ROOT

        do {
            let artistesFolders = try fileManager.contentsOfDirectory(at: roorUrl, includingPropertiesForKeys: nil)
            
            for artisteFolder in artistesFolders {
                if !artisteFolder.hasDirectoryPath {
                    continue
                }
                
                var actualArtiste:Artiste = Artiste(id:UUID(),name: artisteFolder.lastPathComponent,songs: [])
            
                let songsFolders = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: artisteFolder.path),includingPropertiesForKeys: nil)
                
                for songFolder in songsFolders {
                    if !songFolder.hasDirectoryPath {
                        continue
                    }
                    let files = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: songFolder.path),includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
                    
                    let title = songFolder.lastPathComponent
                    let pdf = files.first(where: { $0.pathExtension == "pdf" })
                    let video = files.first(where: { $0.pathExtension == "mp4" || $0.pathExtension == "mov" })
                    
                    let song = Song(id: UUID(), title: title, pdf: pdf, video: video)
                    
                    actualArtiste.songs.append(song)
                    
                }
                artistes.append(actualArtiste)
            }
            
            print(artistes.count)
            
        } catch {
            print("Erreur: \(error)")
        }
        
        return artistes
    }

    
}


#Preview {
    ContentView()
}
