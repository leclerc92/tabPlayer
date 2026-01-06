//
//  SettingView.swift
//  TabPlayer
//
//  Created by clement leclerc on 06/01/2026.
//

import SwiftUI

struct SettingView: View {
    
    @AppStorage("rootFolderURL") var url = ""
    
    var body: some View {
        VStack {
            Text("Prérence de dossier racine")
            HStack{
                TextField("lien vers les dossier racine", text: $url)
                Button("Selectionner dossier") {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseDirectories = true
                    openPanel.canChooseFiles = false
                    openPanel.allowsMultipleSelection = false
                    openPanel.runModal()
                    url = openPanel.url?.path ?? ""
                }
            }.padding()
           
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingView()
}
