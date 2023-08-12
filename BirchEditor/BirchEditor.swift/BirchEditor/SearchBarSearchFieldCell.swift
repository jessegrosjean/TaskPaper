//
//  SearchBarSearchFieldCell.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/1/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

class SearchBarSearchFieldCell: NSSearchFieldCell {
    override func searchButtonRect(forBounds bounds: NSRect) -> NSRect {
        var rect = super.searchButtonRect(forBounds: bounds)
        rect.origin.x = 0
        // rect.size.width = 0
        return rect
    }

    override func searchTextRect(forBounds bounds: NSRect) -> NSRect {
        let maxButton = NSMaxX(searchButtonRect(forBounds: bounds))
        let minCancel = NSMinX(cancelButtonRect(forBounds: bounds))

        var rect = super.searchTextRect(forBounds: bounds)
        rect.origin.x = maxButton
        rect.size.width = minCancel - maxButton
        return rect
    }

    override func cancelButtonRect(forBounds rect: NSRect) -> NSRect {
        var rect = super.cancelButtonRect(forBounds: rect)
        rect.origin.x = rect.maxX
        rect.size.width = 0
        return rect
    }

    override func draw(withFrame _: NSRect, in _: NSView) {
        // drawInterior(withFrame: cellFrame, in: controlView)
    }
}
