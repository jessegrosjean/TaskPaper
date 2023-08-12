//
//  NSPoint.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

extension NSPoint {
    public func pointByTranslating(_ delta: NSPoint) -> NSPoint {
        var translatedPoint = self
        translatedPoint.x += delta.x
        translatedPoint.y += delta.y
        return translatedPoint
    }

    public func pointByNegation() -> NSPoint {
        var p = self
        p.x = -p.x
        p.y = -p.y
        return p
    }
}
