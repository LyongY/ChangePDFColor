//
//  DragableView.swift
//  Language Tool
//
//  Created by Raysharp666 on 2019/11/11.
//  Copyright © 2019 LyongY. All rights reserved.
//

import SwiftUI

struct DragableView: View {
    
    var canDragIn: (_ path: String) -> Bool
    var dragIn: (_ path: String) -> Void
    init(canDragIn: @escaping (_ path: String) -> Bool, dragIn: @escaping (_ path: String) -> Void) {
        self.canDragIn = canDragIn
        self.dragIn = dragIn
    }

    init(dragFileIn: @escaping (_ path: String) -> Void) {
        self.canDragIn = { path in
            DragableView.isFile(path)
        }
        self.dragIn = dragFileIn
    }

    init(dragDirectoryIn: @escaping (_ path: String) -> Void) {
        self.canDragIn = { path in
            !DragableView.isFile(path)
        }
        self.dragIn = dragDirectoryIn
    }

    private static func isFile(_ path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let isExist = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        if isExist && !isDirectory.boolValue {
            return true
        }
        return false
    }

    @State var isDragIn: Bool = false

    var body: some View {
        DragableViewRepresentable(isDragIn: $isDragIn, canDragIn: canDragIn, dragIn: dragIn)
            .overlay(Rectangle().stroke(isDragIn ? Color.blue : Color.gray, lineWidth: isDragIn ? 3 : 2))
    }
}

struct DragableView_Previews: PreviewProvider {
    static var previews: some View {
        DragableView { path in
            true
        } dragIn: { path in

        }

    }
}

struct DragableViewRepresentable: NSViewRepresentable {

    @Binding var isDragIn: Bool

    var canDragIn: (_ path: String) -> Bool
    var dragIn: (_ path: String) -> Void

    
    func makeNSView(context: NSViewRepresentableContext<DragableViewRepresentable>) -> NSView {
        let view = DragableViewContent(parent: self)
        view.registerForDraggedTypes([.fileContents, .fileURL])
        return view
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<DragableViewRepresentable>) {
    }
}

class DragableViewContent: NSView {
        
    var parent: DragableViewRepresentable
    
    init(parent: DragableViewRepresentable) {
        self.parent = parent
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func pathStr(_ sender: NSDraggingInfo) -> String? {
        let pasteBoard = sender.draggingPasteboard
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options: nil), urls.count > 0 {
            let url = urls.first as! NSURL
            
            if let path = url.path {
                return path
            }
        }
        return nil
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let path = pathStr(sender) {
            if parent.canDragIn(path) {
                self.parent.isDragIn = true
            }
        }
        return .link
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.parent.isDragIn = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.parent.isDragIn = false
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.parent.isDragIn = false

        if let path = pathStr(sender) {
            if parent.canDragIn(path) {
                parent.dragIn(path)
            }
            return true
        }
        return false
    }

}
