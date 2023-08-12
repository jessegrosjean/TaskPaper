//
//  OutlineSidebarRowView.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/17/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

class OutlineSidebarRowView: NSTableRowView {
    override func drawSelection(in dirtyRect: NSRect) {
        NSColor(red: 94 / 255.0, green: 151 / 255.0, blue: 247 / 255.0, alpha: 1.0).set()
        dirtyRect.fill()
    }
}
