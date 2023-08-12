//
//  OutlineEditorLayoutManager.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa
import CoreText
import Foundation

class OutlineEditorLayoutManager: NSLayoutManager {
    let outlineEditor: OutlineEditorType

    var spaceInvisible: CTLine!
    var tabInvisible: CTLine!
    var newlineInvisible: CTLine!
    var lineSeparatorInvisible: CTLine!
    var newlineInvisibleSpacing: CGFloat = 1.5
    var newlineInvisibleAdvance: CGFloat = 0
    var lineSeparatorInvisibleAdvance: CGFloat = 0

    var outlineEditorComputedStyle: ComputedStyle? {
        didSet {
            if let computedStyle = outlineEditorComputedStyle {
                guidesColor = computedStyle.allValues[.guideLineColor] as? NSColor
                guidesWidth = computedStyle.allValues[.guideLineWidth] as? CGFloat ?? 1
                invisiblesColor = computedStyle.allValues[.invisiblesColor] as? NSColor ?? NSColor.blue
                invisiblesFont = computedStyle.attributedStringValues[.font] as? NSFont ?? NSFont.systemFont(ofSize: 0)
            }
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(outlineEditor: OutlineEditorType) {
        self.outlineEditor = outlineEditor
        super.init()
        typesetter = OutlineEditorTypesetter()
        backgroundLayoutEnabled = false
        allowsNonContiguousLayout = true
    }

    var drawGapsAndGuides: Bool = true {
        didSet {
            invalidateDisplay(forGlyphRange: NSRange(location: 0, length: numberOfGlyphs))
        }
    }

    var guidesColor: NSColor? {
        didSet {
            invalidateDisplay(forGlyphRange: NSRange(location: 0, length: numberOfGlyphs))
        }
    }

    var guidesWidth: CGFloat = 1 {
        didSet {
            invalidateDisplay(forGlyphRange: NSRange(location: 0, length: numberOfGlyphs))
        }
    }

    var drawInvisibles: Bool = true {
        didSet {
            invalidateDisplay(forGlyphRange: NSRange(location: 0, length: numberOfGlyphs))
        }
    }

    var invisiblesColor: NSColor = NSColor.blue {
        didSet {
            invalidateDisplay(forGlyphRange: NSRange(location: 0, length: numberOfGlyphs))
        }
    }

    var invisiblesFont: NSFont = NSFont.userFont(ofSize: 0)! {
        didSet {
            let invisiblesAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: invisiblesColor,
                .font: invisiblesFont,
            ]

            spaceInvisible = CTLineCreateWithAttributedString(NSAttributedString(string: "·", attributes: invisiblesAttributes))
            tabInvisible = CTLineCreateWithAttributedString(NSAttributedString(string: "→", attributes: invisiblesAttributes))
            newlineInvisible = CTLineCreateWithAttributedString(NSAttributedString(string: "¶", attributes: invisiblesAttributes))
            lineSeparatorInvisible = CTLineCreateWithAttributedString(NSAttributedString(string: "↵", attributes: invisiblesAttributes))

            newlineInvisibleAdvance = CGFloat(CTLineGetTypographicBounds(newlineInvisible, nil, nil, nil)) + newlineInvisibleSpacing
            lineSeparatorInvisibleAdvance = CGFloat(CTLineGetTypographicBounds(lineSeparatorInvisible, nil, nil, nil)) + newlineInvisibleSpacing
        }
    }

    func lineSeparatorAdvanceForStorageItem(_: OutlineEditorTextStorageItem?, lineCharacterRange: NSRange) -> CGFloat {
        if let lineBreakCharacter = textStorage?.character(at: UInt(NSMaxRange(lineCharacterRange))) {
            if lineBreakCharacter == UInt16(NSEvent.SpecialKey.lineSeparator.rawValue) {
                return lineSeparatorInvisibleAdvance
            }
        }
        return newlineInvisibleAdvance
    }

    func snapshotForGlyphRangeWithoutGuides(_ glyphRange: NSRange, textContainer: NSTextContainer? = nil) -> (image: NSImage, bounds: NSRect) {
        let savedDrawGuides = drawGapsAndGuides
        drawGapsAndGuides = false
        let result = snapshotForGlyphRange(glyphRange, textContainer: textContainer)
        drawGapsAndGuides = savedDrawGuides
        return result
    }

    override func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        if drawInvisibles {
            if let textStorage = textStorage as? OutlineEditorTextStorage, let textView = textViewForBeginningOfSelection, let textContainer = textView.textContainer {
                let selectedRange = textView.selectedRange
                let selectedGlyphRange = glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
                let drawInvisiblesGlyphRange = NSIntersectionRange(glyphsToShow, selectedGlyphRange)

                let spaceUnichar = UInt16(UnicodeScalar(" ").value)
                let tabUnichar = UInt16(UnicodeScalar("\t").value)
                let newlineUnichar = UInt16(UnicodeScalar("\n").value)
                let lineSeparatorUnichar = UInt16(NSEvent.SpecialKey.lineSeparator.rawValue)

                if drawInvisiblesGlyphRange.location != NSNotFound, drawInvisiblesGlyphRange.length > 0 {
                    let context = (NSGraphicsContext.current?.cgContext)!
                    let charRange = characterRange(forGlyphRange: drawInvisiblesGlyphRange, actualGlyphRange: nil)
                    let startIndex = charRange.location
                    let endIndex = startIndex.advanced(by: charRange.length - 1)

                    context.saveGState()
                    context.scaleBy(x: 1.0, y: -1.0)
                    context.setTextDrawingMode(.fill)

                    var intCharIndex = charRange.location

                    for charIndex in startIndex ... endIndex {
                        let char = textStorage.character(at: UInt(charIndex))
                        var replacementLine: CTLine?
                        var centerInvisible = false
                        var xSpacing: CGFloat = 0

                        if char == spaceUnichar { // space
                            replacementLine = spaceInvisible
                        } else if char == tabUnichar {
                            replacementLine = tabInvisible
                            centerInvisible = true
                        } else if char == lineSeparatorUnichar {
                            xSpacing = newlineInvisibleSpacing
                            replacementLine = lineSeparatorInvisible
                        } else if char == newlineUnichar {
                            xSpacing = newlineInvisibleSpacing
                            replacementLine = newlineInvisible
                        }

                        if let replacementLine = replacementLine {
                            let glyphIndex = glyphIndexForCharacter(at: intCharIndex)
                            let glyphRange = NSMakeRange(glyphIndex, 1)

                            // boundingRect(forGlyphRange:in:) won't work here. Works for all char except trailing newline.
                            enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: glyphRange, in: textContainer, using: { rect, stop in
                                var replacedRect = rect.rectByTranslating(origin)
                                var accent: CGFloat = 0, descent: CGFloat = 0
                                let advance = CGFloat(CTLineGetTypographicBounds(replacementLine, &accent, &descent, nil))
                                let height = accent + descent

                                replacedRect.origin.y = -NSMaxY(replacedRect)

                                var replacementRect = replacedRect
                                replacementRect.size.width = advance
                                replacementRect.size.height = height
                                if centerInvisible {
                                    replacementRect.origin.x += (replacedRect.size.width - replacementRect.size.width) / 2.0
                                }

                                replacementRect.origin.y += (replacedRect.size.height - replacementRect.size.height) / 2.0

                                context.textPosition = CGPoint(x: replacementRect.origin.x + xSpacing, y: replacementRect.origin.y + descent)

                                stop.pointee = true
                            })
                            CTLineDraw(replacementLine, context)
                        }
                        intCharIndex += 1
                    }
                    context.restoreGState()
                }
            }
        }
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
    }

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: NSPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard
            let outlineEditorTextStorage = textStorage as? OutlineEditorTextStorage,
            let outlineEditor = outlineEditorTextStorage.outlineEditor,
            let textView = textViewForBeginningOfSelection as? OutlineEditorView
        else {
            return
        }

        let effectedRange = outlineEditorTextStorage.paragraphRange(for: characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil))

        if let guidesColor = guidesColor, drawGapsAndGuides {
            let guidesPath = NSBezierPath()

            for each in outlineEditor.guideRangesForVisibleRange(effectedRange) {
                if let ancestor = outlineEditorTextStorage.storageItemAtIndex(each.location), let itemStyle = ancestor.itemComputedStyle {
                    if let handleSize = itemStyle.allValues[.handleSize] as? CGFloat {
                        let handleColor = itemStyle.allValues[.handleColor]
                        let handleBorderColor = itemStyle.allValues[.handleBorderColor]

                        if handleColor != nil || handleBorderColor != nil {
                            if let lastVisibleDescendent = outlineEditorTextStorage.storageItemAtIndex(each.location + each.length - 1) {
                                let topHandleRect = ancestor.itemGeometry(self).handleRect

                                let x = NSMidX(topHandleRect) + -0.5 + origin.x
                                let y = NSMidY(topHandleRect) + (handleSize / 2.0) + origin.y
                                let height = (NSMaxY(lastVisibleDescendent.itemGeometry(self).itemRect) + origin.y) - y
                                var guideLineRect = NSMakeRect(x, y, 1, height)

                                guideLineRect = textView.centerScanRect(guideLineRect)
                                guidesPath.move(to: NSMakePoint(guideLineRect.origin.x + 0.5, guideLineRect.origin.y))
                                guidesPath.line(to: NSMakePoint(guideLineRect.origin.x + 0.5, guideLineRect.origin.y + guideLineRect.size.height))
                            }
                        }
                    }
                }
            }

            guidesColor.set()
            guidesPath.lineWidth = guidesWidth
            guidesPath.stroke()

            if outlineEditor.selectedRange.length > 0 {
                let space = CGFloat(1.5)
                let radius = guidesWidth * 2
                let pattern: [CGFloat] = [radius * 0, radius * (space + 1)]
                let selectedGapsPath = NSBezierPath()
                selectedGapsPath.setLineDash(pattern, count: 2, phase: 0)
                selectedGapsPath.lineCapStyle = .round

                (outlineEditor.computedStyle?.attributedStringValues[.backgroundColor] as? NSColor)?.set()

                let gaps = outlineEditor.gapLocationsForVisibleRange(effectedRange)
                for i in stride(from: 0, to: gaps.count - 1, by: 2) {
                    if let gapAfterItem = outlineEditorTextStorage.storageItemAtIndex(gaps[i]) {
                        let gapSelected = CGFloat(gaps[i + 1]) != 0
                        let geometry = gapAfterItem.itemGeometry(self)
                        let rect = geometry.itemRect.rectByTranslating(origin)
                        let minXmaxY = rect.minXmaxY
                        let start = minXmaxY
                        let end = NSMakePoint(rect.maxX, rect.maxY)

                        if gapSelected {
                            selectedGapsPath.move(to: start)
                            selectedGapsPath.line(to: end)
                        }
                    }
                }

                invisiblesColor.set()
                selectedGapsPath.lineWidth = radius
                selectedGapsPath.stroke()
            }
        }

        outlineEditorTextStorage.enumerateParagraphRanges(in: effectedRange) { enclosingRange, _ in
            if let storageItem = outlineEditorTextStorage.storageItemAtIndex(enclosingRange.location) {
                storageItem.renderIntoLayoutManager(self, atItemRange: enclosingRange, atPoint: origin)
            }
        }
    }
}
