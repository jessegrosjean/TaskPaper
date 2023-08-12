//
//  NSWindow-CenterOnScreen.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

extension NSWindow {
    func centerOnScreen(_ screen: NSScreen?) {
        if let screen = screen ?? self.screen {
            let screenFrame = screen.visibleFrame
            let screenSize = screenFrame.size
            let origin = NSPoint(
                x: screenFrame.minX + (screenSize.width - frame.size.width) / 2,
                y: screenFrame.minY + (screenSize.height - frame.size.height) / 2
            )
            setFrameOrigin(origin)
        }
    }

    func centerOnWindow(_ window: NSWindow?) {
        if let window = window {
            let windowFrame = window.frame
            let windowSize = windowFrame.size
            let origin = NSPoint(
                x: windowFrame.minX + (windowSize.width - frame.size.width) / 2,
                y: windowFrame.minY + (windowSize.height - frame.size.height) / 2
            )
            setFrameOrigin(origin)
        }
    }
}
