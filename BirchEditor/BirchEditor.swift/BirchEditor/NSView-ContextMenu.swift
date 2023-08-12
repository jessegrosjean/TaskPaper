//
//  NSView-ContextMenu.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/4/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

extension NSView {
    func simulateClickToShowContextMenu(_ localPoint: NSPoint) {
        let location = convert(localPoint, to: nil)

        let event = NSEvent.mouseEvent(
            with: .leftMouseDown,
            location: location,
            modifierFlags: [],
            timestamp: NSDate.timeIntervalSinceReferenceDate,
            windowNumber: window!.windowNumber,
            context: NSGraphicsContext.current,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        )

        if let event = event {
            NSApp.sendEvent(event)
        }
    }
}
