//
//  ChoicePaletteWindow.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

class ChoicePaletteWindow: NSPanel {
    override init(contentRect: NSRect, styleMask _: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: .borderless, backing: bufferingType, defer: flag)
        commonInit()
    }

    override var canBecomeKey: Bool {
        return true
    }

    func commonInit() {
        isOpaque = false
        backgroundColor = NSColor.windowBackgroundColor
        styleMask = [.titled, .fullSizeContentView, .utilityWindow]
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        showsToolbarButton = false
        standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
        standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
        standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
        standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
    }
}
