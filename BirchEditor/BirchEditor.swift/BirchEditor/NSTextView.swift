//
//  NSTextView.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/6/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

extension NSTextView {
    public func rectForRange(_ characterRange: NSRange) -> NSRect {
        guard let layoutManager = layoutManager, let textContainer = textContainer else {
            return NSZeroRect
        }

        // layoutManger.enumerateEnclosingRects might be better? Hard to say.
        // I think current implementation is more acurate, but layoutManger.enumerateEnclosingRects
        // better represents selection rects. Not sure which is faster.
        let glyphRange = layoutManager.glyphRange(forCharacterRange: characterRange, actualCharacterRange: nil)
        let boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        return boundingRect.rectByTranslating(textContainerOrigin)
    }

    public func characterRangeRect(_ characterRange: NSRange, containsPoint point: NSPoint) -> Bool {
        return rectForRange(characterRange).contains(point)
    }

    public func characterIndexForLocalPoint(_ localPoint: NSPoint, partialFraction: UnsafeMutablePointer<CGFloat>? = nil) -> Int {
        return layoutManager!.characterIndex(
            for: localPoint.pointByTranslating(textContainerOrigin.pointByNegation()),
            in: textContainer!,
            fractionOfDistanceBetweenInsertionPoints: partialFraction
        )
    }

    public func selectSentence() {
        var selectedRange = self.selectedRange()
        if let textStorage = textStorage {
            let paragraphRange = textStorage.paragraphRange(for: selectedRange)
            textStorage.enumerateSubstrings(in: paragraphRange, options: NSString.EnumerationOptions.bySentences, using: { s, r1, _, _ in
                if NSIntersectionRange(selectedRange, r1).length > 0 || NSLocationInRange(selectedRange.location, r1) {
                    if s?.hasSuffix("\n") ?? false, r1.length > 0 {
                        selectedRange = NSUnionRange(selectedRange, NSMakeRange(r1.location, r1.length - 1))
                    } else {
                        selectedRange = NSUnionRange(selectedRange, r1)
                    }
                }
            })
        }
        self.selectedRange = selectedRange
    }
}
