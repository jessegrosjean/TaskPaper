//
//  OutlineEditorTypesetter.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

class OutlineEditorTypesetter: NSATSTypesetter {
    var currentTextStorageItem: OutlineEditorTextStorageItem?

    override func beginParagraph() {
        if let textStorage = attributedString as? OutlineEditorTextStorage {
            currentTextStorageItem = textStorage.storageItemAtIndex(paragraphCharacterRange.location)
        }
        super.beginParagraph()
    }

    override func endParagraph() {
        super.endParagraph()
        currentTextStorageItem = nil
    }

    override var attributesForExtraLineFragment: [NSAttributedString.Key: Any] {
        guard let layoutManager = layoutManager as? OutlineEditorLayoutManager else {
            return super.attributesForExtraLineFragment
        }

        return layoutManager.outlineEditor.computedStyle?.inheritedAttributedStringValues ?? super.attributesForExtraLineFragment
    }

    override func getLineFragmentRect(_ lineFragmentRect: NSRectPointer,
                                      usedRect lineFragmentUsedRect: NSRectPointer,
                                      remaining remainingRect: NSRectPointer,
                                      forStartingGlyphAt startingGlyphIndex: Int,
                                      proposedRect: NSRect,
                                      lineSpacing: CGFloat,
                                      paragraphSpacingBefore: CGFloat,
                                      paragraphSpacingAfter: CGFloat) {
        
        if let tc = currentTextContainer as? OutlineEditorTextContainer {
            tc.itemIndentLevel = currentTextStorageItem?.indentLevel ?? 1
        }

        super.getLineFragmentRect(lineFragmentRect, usedRect: lineFragmentUsedRect, remaining: remainingRect, forStartingGlyphAt: startingGlyphIndex, proposedRect: proposedRect, lineSpacing: lineSpacing, paragraphSpacingBefore: paragraphSpacingBefore, paragraphSpacingAfter: paragraphSpacingAfter)

        let paragraphStartGlyphLocation = paragraphGlyphRange.location
        if startingGlyphIndex != paragraphStartGlyphLocation {
            if let item = currentTextStorageItem, let lm = layoutManager, item.type == "task" {
                let start = lm.location(forGlyphAt: paragraphStartGlyphLocation)
                let end = lm.location(forGlyphAt: paragraphStartGlyphLocation + 2)
                let adjust = end.x - start.x
                lineFragmentRect.pointee.origin.x += adjust
                lineFragmentRect.pointee.size.width -= adjust
            }
        }
    }

    override func willSetLineFragmentRect(_ lineRect: UnsafeMutablePointer<NSRect>, forGlyphRange glyphRange: NSRange, usedRect: UnsafeMutablePointer<NSRect>, baselineOffset: UnsafeMutablePointer<CGFloat>) {
        let paragraphStyle = currentParagraphStyle!
        let font = attributedString?.attribute(NSAttributedString.Key.font, at: paragraphCharacterRange.location, effectiveRange: nil) as! NSFont
        var unusedHeight: CGFloat = lineRect.pointee.size.height - usedRect.pointee.size.height
        var beforeSpacing: CGFloat = 0
        var afterSpacing: CGFloat = 0
        if unusedHeight > 0, glyphRange.location != 0, glyphRange.location == paragraphGlyphRange.location {
            beforeSpacing = paragraphStyle.paragraphSpacingBefore
            unusedHeight -= beforeSpacing
        }

        if unusedHeight > 0 {
            afterSpacing = paragraphStyle.paragraphSpacing
        }

        // lineRect.pointee.size.width = usedRect.pointee.size.width + (usedRect.pointee.origin.x - lineRect.pointee.origin.x)

        if let layoutManager = layoutManager as? OutlineEditorLayoutManager {
            // Room is made for this expansion by textContainer.roomForTrailingInvisibles
            lineRect.pointee.size.width += layoutManager.lineSeparatorAdvanceForStorageItem(currentTextStorageItem, lineCharacterRange: paragraphCharacterRange)
        }

        baselineOffset.pointee = ((lineRect.pointee.size.height + beforeSpacing - afterSpacing) / 2.0) + (font.xHeight / 2.0)
    }

    override func setAttachmentSize(_ attachmentSize: NSSize, forGlyphRange glyphRange: NSRange) {
        super.setAttachmentSize(attachmentSize, forGlyphRange: glyphRange)
    }

    override func setLocation(_ location: NSPoint, withAdvancements advancements: UnsafePointer<CGFloat>, forStartOfGlyphRange glyphRange: NSRange) {
        super.setLocation(location, withAdvancements: advancements, forStartOfGlyphRange: glyphRange)
    }
}
