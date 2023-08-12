//
//  HandleDragGestureRecognizer.swift
//  Birch
//
//  Created by Jesse Grosjean on 11/11/16.
//
//

import Cocoa

class OutlineEditorHandleDragStartGestureRecognizer: NSGestureRecognizer {
    var mouseDown: NSPoint?
    var minimumDragDistance: Float = 5

    override func reset() {
        mouseDown = nil
        super.reset()
    }

    override func mouseDown(with event: NSEvent) {
        mouseDown = event.locationInWindow
        state = .possible
    }

    override func mouseDragged(with event: NSEvent) {
        if state == .possible, let mouseDown = mouseDown {
            let current = event.locationInWindow
            let distance = hypotf(Float(mouseDown.x - current.x), Float(mouseDown.y - current.y))
            if distance > minimumDragDistance {
                state = .recognized
            }
        }
    }

    override func mouseUp(with _: NSEvent) {
        if state == .possible {
            state = .failed
        }
    }
}
