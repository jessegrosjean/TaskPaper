//
//  OutlineEditorTextClipView.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/8/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

class OutlineEditorTextClipView: NSClipView {
    override func scroll(to newOrigin: NSPoint) {
        var p = newOrigin
        p.x = p.x.rounded()
        p.y = p.y.rounded()
        if p.x != 0 {
            // Clap x to 0. Sometimes when scrolling very fast (very big view) x comes in as a non zero... not sure why. Seems to be a genral bug, as I can make it happen in xCode.
            super.scroll(to: NSMakePoint(0, p.y))
        } else {
            super.scroll(to: p)
        }
    }
}
