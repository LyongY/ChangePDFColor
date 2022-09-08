//
//  PDFView.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/7.
//

import SwiftUI
import AppKit
import PDFKit

struct PDFViewRepresentable: NSViewRepresentable {

    let path: String

    func makeNSView(context: NSViewRepresentableContext<PDFViewRepresentable>) -> NSView {
        let view = PDFView()
        let doc = PDFDocument(url: URL(fileURLWithPath: path))
        view.document = doc
        view.autoScales = true
        return view
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<PDFViewRepresentable>) {
        if let pdfView = nsView as? PDFView {
            let doc = PDFDocument(url: URL(fileURLWithPath: path))
            pdfView.document = doc
        }
    }
}
