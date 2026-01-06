//
//  PDFKitView.swift
//  TabPlayer
//
//  Created by clement leclerc on 06/01/2026.
//

import SwiftUI
import PDFKit

struct PDFKitView: NSViewRepresentable {
    
    var url : URL
    
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url:url)
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = PDFDocument(url:url)
    }
}
