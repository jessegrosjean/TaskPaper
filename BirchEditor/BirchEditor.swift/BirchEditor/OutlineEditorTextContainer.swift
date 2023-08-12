//
//  OutlineEditorTextContainer.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

class OutlineEditorTextContainer: NSTextContainer {
    override init(size: NSSize) {
        super.init(size: size)
    }

    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func contains(_: NSPoint) -> Bool {
        return true
    }

    override var isSimpleRectangularTextContainer: Bool {
        return true
    }

    var itemIndentPerLevel: CGFloat = 20 {
        didSet {
            lineFragmentPadding = itemIndentPerLevel / 2.0
        }
    }

    var itemIndentLevel: CGFloat = 0
    var itemTextWrapWidth: CGFloat = 10000
    var roomForTrailingInvisibles: CGFloat = 0
    let minItemTextWrapWidth: CGFloat = 200

    override func lineFragmentRect(forProposedRect proposedRect: NSRect, at characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remaining remainingRect: UnsafeMutablePointer<NSRect>?) -> NSRect {
        let indent = itemIndentLevel * itemIndentPerLevel
        var itemRect = proposedRect

        itemRect.origin.x += indent
        itemRect.size.width = size.width - (indent + roomForTrailingInvisibles)

        if itemRect.size.width > itemTextWrapWidth {
            itemRect.size.width = itemTextWrapWidth
        }

        let underflow = minItemTextWrapWidth - itemRect.size.width
        if underflow > 0 {
            itemRect.origin.x -= underflow
            itemRect.size.width = minItemTextWrapWidth
        }

        return super.lineFragmentRect(forProposedRect: itemRect, at: characterIndex, writingDirection: baseWritingDirection, remaining: remainingRect)
    }
}
