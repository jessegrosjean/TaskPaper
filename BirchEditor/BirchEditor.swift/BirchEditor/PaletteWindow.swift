//
//  PaletteWindow.swift
//  Birch
//
//  Created by Jesse Grosjean on 10/28/16.
//
//

import Cocoa

class PaletteWindow: NSPanel {
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
