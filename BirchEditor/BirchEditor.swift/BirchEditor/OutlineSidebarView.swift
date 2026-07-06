//
//  OutlineSidebarView.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/27/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

class OutlineSidebarView: NSOutlineView {
    override func keyDown(with theEvent: NSEvent) {
        if let characters = theEvent.charactersIgnoringModifiers {
            switch characters {
            case "\r", "\n":
                doCommand(by: #selector(insertNewline(_:)))
            case String(describing: UnicodeScalar(NSEvent.SpecialKey.delete.rawValue)):
                doCommand(by: #selector(deleteBackward(_:)))
            default:
                super.keyDown(with: theEvent)
            }
        } else {
            super.keyDown(with: theEvent)
        }
    }

    // override func restoreStateWithCoder(coder: NSCoder) {
    //    super.restoreStateWithCoder(coder)
    // }

    override func reloadItem(_ item: Any?) {
        // fix http://stackoverflow.com/questions/19963031/nsoutlineview-reloaditem-has-no-effect
        // reload item broken for view based outlineviews
        reloadData(forRowIndexes: IndexSet(integer: row(forItem: item)), columnIndexes: IndexSet(integersIn: 0 ..< numberOfColumns))
    }

    override func frameOfCell(atColumn column: Int, row: Int) -> NSRect {
        var frame = super.frameOfCell(atColumn: column, row: row)

        let level = self.level(forRow: row) + 1
        let indent = CGFloat(level) * indentationPerLevel

        frame.origin.x = indent
        frame.size.width = self.frame.width - (indent + indentationPerLevel)

        return frame
    }
}
