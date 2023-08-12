//
//  NSLayoutManager.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

extension NSLayoutManager {
    public var drawsGuides: Bool {
        get {
            return false
        }
        set(value) {}
    }

    public func snapshotForGlyphRange(_ glyphRange: NSRange, textContainer: NSTextContainer? = nil) -> (image: NSImage, bounds: NSRect) {
        let tc = textContainer ?? textContainers[0]
        let tv = tc.textView

        var rect = boundingRect(forGlyphRange: glyphRange, in: tc)
        rect = tv!.centerScanRect(rect)
        rect.size.width += rect.origin.x
        rect.origin.x = 0

        let image = NSImage(size: rect.size)
        let point = rect.origin.pointByNegation()
        let savedDrawsGuides = drawsGuides

        image.lockFocusFlipped(true)
        drawsGuides = false
        drawBackground(forGlyphRange: glyphRange, at: point)
        drawGlyphs(forGlyphRange: glyphRange, at: point)
        drawsGuides = savedDrawsGuides
        image.unlockFocus()

        return (image: image, bounds: rect)
    }
}
