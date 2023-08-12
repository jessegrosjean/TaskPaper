//
//  NSRect.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/5/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

extension NSRect {
    var minXminY: NSPoint {
        return NSMakePoint(minX, minY)
    }

    var minXmaxY: NSPoint {
        return NSMakePoint(minX, maxY)
    }

    var maxXminY: NSPoint {
        return NSMakePoint(maxX, minY)
    }

    var maxXmaxY: NSPoint {
        return NSMakePoint(maxX, maxY)
    }

    public func rectByCenteringInRect(_ outerRect: NSRect) -> NSRect {
        var centeredRect = self
        centeredRect.origin.x = outerRect.origin.x + (outerRect.size.width - centeredRect.size.width) / 2.0
        centeredRect.origin.y = outerRect.origin.y + (outerRect.size.height - centeredRect.size.height) / 2.0
        return centeredRect
    }

    public func rectByTranslating(_ delta: NSPoint) -> NSRect {
        var translatedRect = self
        translatedRect.origin.x += delta.x
        translatedRect.origin.y += delta.y
        return translatedRect
    }
}
