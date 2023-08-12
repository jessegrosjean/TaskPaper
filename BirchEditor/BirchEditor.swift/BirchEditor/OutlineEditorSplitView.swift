//
//  OutlineEditorSplitView.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/7/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

class OutlineEditorSplitView: NSSplitView {
    // MARK: - Tracking Areas

    /* var trackingArea: NSTrackingArea?

     override func updateTrackingAreas() {
         if let trackingArea = trackingArea {
             removeTrackingArea(trackingArea)
         }

         var titlebar = bounds
         titlebar.size.height = 22
         trackingArea = NSTrackingArea(rect: titlebar, options: [.MouseEnteredAndExited, .ActiveAlways], owner: self, userInfo: nil)

         addTrackingArea(trackingArea!)
     }

     override func addTrackingArea(trackingArea: NSTrackingArea) {
         super.addTrackingArea(trackingArea)
     }

     override func mouseEntered(theEvent: NSEvent) {
         (self.window?.windowController as? OutlineEditorWindowController)?.hideTitlebarDebouncer?.cancel()
         (self.window?.windowController as? OutlineEditorWindowController)?.showTitlebarDebouncer?.call()
     }

     override func mouseExited(theEvent: NSEvent) {
         (self.window?.windowController as? OutlineEditorWindowController)?.showTitlebarDebouncer?.cancel()
         (self.window?.windowController as? OutlineEditorWindowController)?.hideTitlebarDebouncer?.call()
     } */

    /*
     override var dividerThickness: CGFloat {
         return 0.5
     }
     override func drawDividerInRect(rect: NSRect) {
         switch effectiveAppearance.name {
         case NSAppearanceNameAqua, NSAppearanceNameVibrantLight:
             NSColor.blackColor().colorWithAlphaComponent(0.01).set()
         case NSAppearanceNameVibrantDark:
             NSColor.whiteColor().colorWithAlphaComponent(0.2).set()
         default:
             NSColor.redColor().set()
         }

         NSRectFill(rect)
     }*/
}
