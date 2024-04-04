//
//  OutlineEditorTextStorageItemRenderer.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/6/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

import BirchOutline
import JavaScriptCore

extension NSAttributedString.Key {
    static let storageItemIDAttributeName = NSAttributedString.Key("StorageItemID")
}

public let SharedHandlePath = NSBezierPath()

public struct ItemGeometry {
    let itemRect: NSRect
    let itemUsedRect: NSRect
    let handleRect: NSRect
}

public struct OutlineEditorTextStorageItem {
    struct RunStyle {
        let styleKeyPath: String
        let link: String?
        let length: Int
    }

    let id: String
    let type: String
    let indentLevel: CGFloat
    let styleKeyPath: String
    let runStyles: [RunStyle]
    weak var outlineEditor: OutlineEditorType?

    public var item: ItemType {
        return (outlineEditor as? OutlineEditor)!.jsOutlineEditor.forProperty("outline").invokeMethod("getItemForID", withArguments: [id])!
    }

    var itemComputedStyle: ComputedStyle? {
        return outlineEditor?.styleSheet?.computedStyleForKeyPath(styleKeyPath)
    }

    var bodyRange: NSRange {
        return (outlineEditor as? OutlineEditor)!.jsOutlineEditor.invokeMethod("getDisplayedBodyCharacterRange", withArguments: [id]).toRange()
    }

    var branchRange: NSRange {
        return (outlineEditor as? OutlineEditor)!.jsOutlineEditor.invokeMethod("getDisplayedBranchCharacterRange", withArguments: [id]).toRange()
    }

    public func renderIntoAttributedString(_ attributedString: NSMutableAttributedString, atItemRange itemRange: NSRange) {
        attributedString.addAttribute(.storageItemIDAttributeName, value: id, range: itemRange)

        if let outlineEditor = outlineEditor, let styleSheet = outlineEditor.styleSheet {
            let itemStringAttributes = styleSheet.computedStyleForKeyPath(styleKeyPath).attributedStringValues
            if itemStringAttributes.count > 0 {
                attributedString.noConversionAddAttributes(itemStringAttributes, range: itemRange)
            }

            var runRange = NSMakeRange(itemRange.location, 0)
            for each in runStyles {
                runRange.length = each.length

                let runStringAttributes = styleSheet.computedStyleForKeyPath(each.styleKeyPath).attributedStringSpanValues
                if runStringAttributes.count > 0 {
                    attributedString.noConversionAddAttributes(runStringAttributes, range: runRange)
                }

                if let eachLink = each.link {
                    if eachLink.hasPrefix("button://toggledone") {
                        attributedString.addAttribute(.toggleDoneInternalLink, value: eachLink, range: runRange)
                    } else if eachLink.hasPrefix("filter://") {
                        attributedString.addAttribute(.filterInternalLink, value: eachLink, range: runRange)
                    } else {
                        attributedString.addAttribute(.link, value: eachLink, range: runRange)
                    }
                }

                runRange.location += runRange.length
            }
        }
    }

    public func renderIntoLayoutManager(_ layoutManager: NSLayoutManager, atItemRange itemRange: NSRange, atPoint point: CGPoint) {
        if let itemStyle = itemComputedStyle {
            if let handleSize = itemStyle.allValues[.handleSize] as? CGFloat {
                let geometry = itemGeometryFromRange(itemRange, layoutManager: layoutManager, origin: point)
                var handleBulletRect = NSMakeRect(0, 0, handleSize, handleSize)

                let handleColor = itemStyle.allValues[.handleColor] as? NSColor
                let handleBorderColor = itemStyle.allValues[.handleBorderColor] as? NSColor
                let handleBorderWidth = itemStyle.allValues[.handleBorderWidth] as? CGFloat ?? 1
                if handleBorderColor != nil {
                    handleBulletRect = NSInsetRect(handleBulletRect, handleBorderWidth / 2.0, handleBorderWidth / 2.0)
                }

                SharedHandlePath.removeAllPoints()
                SharedHandlePath.appendOval(in: handleBulletRect.rectByCenteringInRect(geometry.handleRect.rectByTranslating(point)))

                if let handleColor = handleColor {
                    handleColor.set()
                    SharedHandlePath.fill()
                }

                if let handleBorderColor = handleBorderColor {
                    handleBorderColor.set()
                    SharedHandlePath.lineWidth = handleBorderWidth
                    SharedHandlePath.stroke()
                }
            }
        }
    }

    public func itemGeometry(_ layoutManager: NSLayoutManager) -> ItemGeometry {
        return itemGeometryFromRange(bodyRange, layoutManager: layoutManager, origin: layoutManager.firstTextView?.textContainerOrigin ?? NSZeroPoint)
    }

    public func itemGeometryFromRange(_ range: NSRange, layoutManager: NSLayoutManager, origin _: NSPoint) -> ItemGeometry {
        let itemIndent = CGFloat(outlineEditor?.computedItemIndent ?? 17)
        let textContainer = layoutManager.textContainers[0]
        let lineFragmentPadding = textContainer.lineFragmentPadding
        let startGlyphIndex = layoutManager.glyphIndexForCharacter(at: range.location)
        let endGlyphIndex = layoutManager.glyphIndexForCharacter(at: max(0, NSMaxRange(range) - 1))
        var lineFragmentGlyphRange = NSMakeRange(0, 0)
        let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: startGlyphIndex, effectiveRange: &lineFragmentGlyphRange)
        let lineFragmentUsedRect = layoutManager.lineFragmentUsedRect(forGlyphAt: startGlyphIndex, effectiveRange: nil)
        var handleRect = NSMakeRect(lineFragmentUsedRect.origin.x - itemIndent, lineFragmentUsedRect.origin.y, itemIndent, lineFragmentUsedRect.size.height)

        var itemRect = lineFragmentRect
        var itemUsedRect = lineFragmentUsedRect

        var location = NSMaxRange(lineFragmentGlyphRange)
        while location <= endGlyphIndex {
            itemRect = itemRect.union(layoutManager.lineFragmentRect(forGlyphAt: location, effectiveRange: &lineFragmentGlyphRange))
            itemUsedRect = itemUsedRect.union(layoutManager.lineFragmentUsedRect(forGlyphAt: location, effectiveRange: nil))
            location = NSMaxRange(lineFragmentGlyphRange)
        }

        itemRect.origin.x += lineFragmentPadding
        itemRect.size.width -= (lineFragmentPadding * 2)
        itemUsedRect.origin.x += lineFragmentPadding
        itemUsedRect.size.width -= (lineFragmentPadding * 2)
        handleRect.origin.x += lineFragmentPadding

        return ItemGeometry(itemRect: itemRect, itemUsedRect: itemUsedRect, handleRect: handleRect)
    }

    func itemBodySnapshot(_ layoutManager: OutlineEditorLayoutManager) -> (image: NSImage, bounds: NSRect) {
        return layoutManager.snapshotForGlyphRangeWithoutGuides(layoutManager.glyphRange(forCharacterRange: bodyRange, actualCharacterRange: nil))
    }

    func itemBranchSnapshot(_ layoutManager: OutlineEditorLayoutManager) -> (image: NSImage, bounds: NSRect) {
        return layoutManager.snapshotForGlyphRangeWithoutGuides(layoutManager.glyphRange(forCharacterRange: branchRange, actualCharacterRange: nil))
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSAttributedStringKey(_ input: String) -> NSAttributedString.Key {
    return NSAttributedString.Key(rawValue: input)
}
