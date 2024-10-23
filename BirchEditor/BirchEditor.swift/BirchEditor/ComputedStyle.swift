//
//  Style.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/17/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

extension NSAttributedString.Key {
    static let filterInternalLink = NSAttributedString.Key("filterInternalLink")
    static let toggleDoneInternalLink = NSAttributedString.Key("toggleDoneInternalLink")

    static let handleSize = NSAttributedString.Key("handleSize")
    static let secondaryTextColor = NSAttributedString.Key("secondaryTextColor")
    static let placeholderColor = NSAttributedString.Key("placeholderColor")
    static let errorTextColor = NSAttributedString.Key("errorTextColor")
    static let appearance = NSAttributedString.Key("appearance")
    static let handleColor = NSAttributedString.Key("handleColor")
    static let handleBorderColor = NSAttributedString.Key("handleBorderColor")
    static let handleBorderWidth = NSAttributedString.Key("handleBorderWidth")

    static let guideLineColor = NSAttributedString.Key("guideLineColor")
    static let guideLineWidth = NSAttributedString.Key("guideLineWidth")
    static let invisiblesColor = NSAttributedString.Key("invisiblesColor")
    static let itemIndent = NSAttributedString.Key("itemIndent")
    static let caretColor = NSAttributedString.Key("caretColor")

    static let dropIndicatorColor = NSAttributedString.Key("dropIndicatorColor")
    static let uiScale = NSAttributedString.Key("uiScale")
    static let topPaddingPercent = NSAttributedString.Key("topPaddingPercent")
    static let bottomPaddingPercent = NSAttributedString.Key("bottomPaddingPercent")
    static let typewriterScrollPercent = NSAttributedString.Key("typewriterScrollPercent")
    static let selectionBackgroundColor = NSAttributedString.Key("selectionBackgroundColor")

    static let editorWrapToColumn = NSAttributedString.Key("editorWrapToColumn")
    static let itemWrapToColumn = NSAttributedString.Key("itemWrapToColumn")

    /*

     */
}

public struct ComputedStyle {
    let allValues: [NSAttributedString.Key: Any]
    let attributedStringValues: [NSAttributedString.Key: Any]
    let inheritedAttributedStringValues: [NSAttributedString.Key: Any]
    let attributedStringSpanValues: [NSAttributedString.Key: Any]

    init(allValues: [NSAttributedString.Key: Any]) {
        self.allValues = allValues

        var attrStringValues: [NSAttributedString.Key: Any] = [:]
        attrStringValues[.font] = allValues[NSAttributedString.Key.font]
        attrStringValues[.paragraphStyle] = allValues[.paragraphStyle]
        attrStringValues[.foregroundColor] = allValues[.foregroundColor]
        attrStringValues[.backgroundColor] = allValues[.backgroundColor]
        attrStringValues[.ligature] = allValues[.ligature]
        attrStringValues[.kern] = allValues[.kern]
        attrStringValues[.strikethroughStyle] = allValues[.strikethroughStyle]
        attrStringValues[.underlineStyle] = allValues[.underlineStyle]
        attrStringValues[.strokeColor] = allValues[.strokeColor]
        attrStringValues[.strokeWidth] = allValues[.strokeWidth]
        attrStringValues[.shadow] = allValues[.shadow]
        attrStringValues[.textEffect] = allValues[.textEffect]
        attrStringValues[.attachment] = allValues[.attachment]
        attrStringValues[.link] = allValues[.link]
        attrStringValues[.baselineOffset] = allValues[.baselineOffset]
        attrStringValues[.underlineColor] = allValues[.underlineColor]
        attrStringValues[.strikethroughColor] = allValues[.strikethroughColor]
        attrStringValues[.obliqueness] = allValues[.obliqueness]
        attrStringValues[.expansion] = allValues[.expansion]
        attrStringValues[.writingDirection] = allValues[.writingDirection]
        attrStringValues[.verticalGlyphForm] = allValues[.verticalGlyphForm]
        attrStringValues[.cursor] = allValues[.cursor]
        attrStringValues[.toolTip] = allValues[.toolTip]
        attrStringValues[.markedClauseSegment] = allValues[.markedClauseSegment]
        attrStringValues[.textAlternatives] = allValues[.textAlternatives]
        attrStringValues[.spellingState] = allValues[.spellingState]
        attrStringValues[.superscript] = allValues[.superscript]
        attrStringValues[.glyphInfo] = allValues[.glyphInfo]
        attributedStringValues = attrStringValues

        var inheritedAttrStringValues: [NSAttributedString.Key: Any] = [:]
        inheritedAttrStringValues[.foregroundColor] = attrStringValues[.foregroundColor]
        inheritedAttrStringValues[.font] = attrStringValues[.font]
        inheritedAttrStringValues[.paragraphStyle] = attrStringValues[.paragraphStyle]
        inheritedAttributedStringValues = inheritedAttrStringValues

        attrStringValues[.paragraphStyle] = nil

        attributedStringSpanValues = attrStringValues
        // attributedStringSpanValues = attrStringValues as NSDictionary
    }
}
