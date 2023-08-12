//
//  StyleSheet.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/8/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

import BirchOutline
import JavaScriptCore

let baseStyleSheetURL = Bundle.main.url(forResource: "base-stylesheet", withExtension: "less")!
let baseStyleSheetLESS = (try? String(contentsOf: baseStyleSheetURL, encoding: String.Encoding.utf8)) ?? ""
let DefaultStyleSheetURL = "DefaultStyleSheetURL"

open class StyleSheet {
    public static let sharedInstance = BirchEditor.createStyleSheet(nil)

    let jsStyleSheet: JSValue
    var styleKeysToCocoaStyles: [String: ComputedStyle] = [:]

    public static var styleSheetsURLs: [URL] {
        let fileManager = FileManager.default

        if let url = try? fileManager.URLForApplicationsStyleSheetsDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true) {
            if let styleSheetURLs = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles) {
                return styleSheetURLs.filter { $0.pathExtension == "less" }.sorted(by: { (a, b) -> Bool in
                    a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
                })
            }
        }

        return [URL]()
    }

    public static var defaultStyleSheetURL: URL {
        // Occasionally this returns nil even when I'm sure that DefaultStyleSheetURL is set. The times I've been able to reproduce this
        // are when both
        //   - Automatically Show Web Inspector for JSContexts
        //   - Automatically Pause Connection JSContexts
        // are selected.
        if let url = userDefaults.url(forKey: DefaultStyleSheetURL) {
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        for each in styleSheetsURLs {
            if each.lastPathComponent == "Default.less" {
                return each
            }
        }

        return baseStyleSheetURL
    }

    public static func makeDefault(_ styleSheet: StyleSheet) {
        userDefaults.set(styleSheet.source, forKey: DefaultStyleSheetURL)
    }

    init(source: URL?, scriptContext: BirchScriptContext) {
        self.source = source ?? StyleSheet.defaultStyleSheetURL

        var lessText = baseStyleSheetLESS

        if self.source != baseStyleSheetURL {
            let styleSheetLess = (try? String(contentsOf: self.source, encoding: .utf8)) ?? ""
            lessText += "\n\n\(styleSheetLess)"
        }

        var appearance = "light"

        if #available(OSX 10.14, *) {
            let name = NSApp.effectiveAppearance.name
            if name.rawValue.lowercased().contains("dark") {
                appearance = "dark"
            }
        }

        var controlAccentColor = NSColor(hexString: "D24C4A")
        var selectedContentBackgroundColor = NSColor(hexString: "D24C4A")

        if #available(OSX 10.14, *) {
            controlAccentColor = NSColor.controlAccentColor
            selectedContentBackgroundColor = NSColor.selectedContentBackgroundColor
        }

        let userFontSize = max(8, userDefaults.integer(forKey: BUserFontSizeDefaultsKey))
        let processedLessText = lessText
            .replacingOccurrences(of: "$USER_FONT_SIZE", with: String(userFontSize))
            .replacingOccurrences(of: "$APPEARANCE", with: appearance)
            .replacingOccurrences(of: "$CONTROL_ACCENT_COLOR", with: controlAccentColor.hexString)
            .replacingOccurrences(of: "$SELECTED_CONTENT_BACKGROUND_COLOR", with: selectedContentBackgroundColor.hexString)

        jsStyleSheet = scriptContext.jsStyleSheetClass.construct(withArguments: [processedLessText])
    }

    deinit {}

    public let source: URL

    // MARK: - Computed Styles

    func computedStyleForElement(_ element: Any) -> ComputedStyle {
        return computedStyleForKeyPath(computedStyleKeyPathForElement(element))
    }

    func computedStyleKeyPathForElement(_ element: Any) -> String {
        return jsStyleSheet.invokeMethod("getComputedStyleKeyPathForElement", withArguments: [element]).toString()
    }

    func computedStyleForKeyPath(_ keyPath: String) -> ComputedStyle {
        if let computedStyle = styleKeysToCocoaStyles[keyPath] {
            return computedStyle
        }

        let jsComputedStyle = jsStyleSheet.invokeMethod("getComputedStyleForKeyPath", withArguments: [keyPath])
        let computedStyle = computedStyleFromJavascriptComputedStyle(jsComputedStyle)
        styleKeysToCocoaStyles[keyPath] = computedStyle
        return computedStyle
    }

    func computedStyleFromJavascriptComputedStyle(_ javaScriptStyle: JSValue?) -> ComputedStyle {
        var allValues: [NSAttributedString.Key: Any] = [:]

        if let javaScriptStyleDictionary = javaScriptStyle?.selfOrNil()?.toDictionary() as? [String: Any] {
            for (key, value) in javaScriptStyleDictionary {
                switch key {
                case "color":
                    allValues[.foregroundColor] = colorFromJSColor(value)

                case "background-color":
                    allValues[.backgroundColor] = colorFromJSColor(value)

                case "text-underline-color":
                    allValues[.underlineColor] = colorFromJSColor(value)

                case "text-strikethrough-color":
                    allValues[.strikethroughColor] = colorFromJSColor(value)

                case "text-baseline-offset":
                    allValues[.baselineOffset] = value as? NSNumber

                case "text-expansion":
                    allValues[.expansion] = value as? NSNumber

                case "text-decoration":
                    if let value = value as? String {
                        switch value {
                        case "none":
                            allValues[.underlineStyle] = nil
                            allValues[.strikethroughStyle] = nil
                        case "underline":
                            allValues[.underlineStyle] = NSUnderlineStyle.single.rawValue
                            allValues[.strikethroughStyle] = nil
                        case "line-through":
                            allValues[.underlineStyle] = nil
                            allValues[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                        default:
                            break
                        }
                    }

                case "text-underline":
                    if let value = value as? String {
                        allValues[.underlineStyle] = lineStyleFromString(value)?.rawValue
                    }

                case "text-strikethrough":
                    if let value = value as? String {
                        allValues[.strikethroughStyle] = lineStyleFromString(value)?.rawValue
                    }

                case "appearance":
                    switch value as! String {
                    case "NSAppearanceNameVibrantDark":
                        allValues[.appearance] = NSAppearance(named: NSAppearance.Name.vibrantDark)
                    case "NSAppearanceNameVibrantLight":
                        allValues[.appearance] = NSAppearance(named: NSAppearance.Name.vibrantLight)
                    case "NSAppearanceNameAqua":
                        allValues[.appearance] = NSAppearance(named: NSAppearance.Name.aqua)
                    default:
                        allValues[.appearance] = nil
                    }

                case "caret-width":
                    allValues[.caretWidth] = value

                case "guide-line-width":
                    allValues[.guideLineWidth] = value

                case "ui-scale":
                    allValues[.uiScale] = value

                case "item-indent":
                    allValues[.itemIndent] = value

                case "handle-border-width":
                    allValues[.handleBorderWidth] = value

                case "handle-size":
                    allValues[.handleSize] = value

                case "selection-background-color":
                    allValues[.selectionBackgroundColor] = colorFromJSColor(value)

                case "handle-color":
                    allValues[.handleColor] = colorFromJSColor(value)

                case "invisibles-color":
                    allValues[.invisiblesColor] = colorFromJSColor(value)

                case "drop-indicator-color":
                    allValues[.dropIndicatorColor] = colorFromJSColor(value)

                case "guide-line-color":
                    allValues[.guideLineColor] = colorFromJSColor(value)

                case "caret-color":
                    allValues[.caretColor] = colorFromJSColor(value)

                case "handle-border-color":
                    allValues[.handleBorderColor] = colorFromJSColor(value)

                case "error-text-color":
                    allValues[.errorTextColor] = colorFromJSColor(value)

                case "placeholder-color":
                    allValues[.placeholderColor] = colorFromJSColor(value)

                case "secondary-text-color":
                    allValues[.secondaryTextColor] = colorFromJSColor(value)

                case "top-padding-percent":
                    allValues[.topPaddingPercent] = value

                case "bottom-padding-percent":
                    allValues[.bottomPaddingPercent] = value

                case "typewriter-scroll-percent":
                    allValues[.typewriterScrollPercent] = value

                case "editor-wrap-to-column":
                    allValues[.editorWrapToColumn] = value

                case "item-wrap-to-column":
                    allValues[.itemWrapToColumn] = value

                default:
                    break
                }
            }

            allValues[.paragraphStyle] = paragraphStyleFromJSStyle(javaScriptStyleDictionary)
            allValues[.cursor] = cursorFromJSStyle(javaScriptStyleDictionary)
            allValues[.font] = fontFromJSStyle(javaScriptStyleDictionary)
        }

        return ComputedStyle(allValues: allValues)
    }
}

func colorFromJSColor(_ value: Any) -> NSColor? {
    if let components = value as? [CGFloat] {
        return NSColor(srgbRed: components[0] / 255.0,
                       green: components[1] / 255.0,
                       blue: components[2] / 255.0,
                       alpha: components[3])
    }
    return nil
}

func numberFromJSNumber(_ value: Any) -> NSNumber? {
    if let number = value as? NSNumber {
        return number
    }
    return nil
}

func lineStyleFromString(_ string: String) -> NSUnderlineStyle? {
    var style: NSUnderlineStyle = []
    var pattern: NSUnderlineStyle = []
    var word: NSUnderlineStyle = []

    for each in string.split(separator: " ") {
        switch String(each) {
        case "NSUnderlineStyleNone":
            style = []
        case "NSUnderlineStyleSingle":
            style = NSUnderlineStyle.single
        case "NSUnderlineStyleThick":
            style = NSUnderlineStyle.thick
        case "NSUnderlineStyleDouble":
            style = NSUnderlineStyle.double
        // case "NSUnderlinePatternSolid":
        //    pattern = .patternSolid
        case "NSUnderlinePatternDot":
            pattern = .patternDot
        case "NSUnderlinePatternDash":
            pattern = .patternDash
        case "NSUnderlinePatternDashDot":
            pattern = .patternDashDot
        case "NSUnderlinePatternDashDotDot":
            pattern = .patternDashDotDot
        case "NSUnderlineByWord":
            word = .byWord
        default:
            break
        }
    }

    if style.isEmpty, pattern.isEmpty, word.isEmpty {
        return nil
    }

    return NSUnderlineStyle(rawValue: style.rawValue | pattern.rawValue | word.rawValue)
}

func fontFromJSStyle(_ jsStyle: [String: Any]) -> NSFont? {
    let font = NSFont.userFont(ofSize: 0)!
    var fontTraitMask = NSFontTraitMask()
    var fontSize = font.pointSize
    var fontFamily = ""
    var fontWeight = 5

    if let fontFamilies = jsStyle["font-family"] as? [NSString] {
        for each in fontFamilies {
            let eachTrimmed = each.trimmingCharacters(in: CharacterSet.whitespaces)
            if eachTrimmed == "-apple-system" {
                fontFamily = NSFont.systemFont(ofSize: 0).fontName
            } else if eachTrimmed == "-apple-user" {
                fontFamily = NSFont.userFont(ofSize: 0)?.fontName ?? NSFont.systemFont(ofSize: 0).fontName
            } else {
                if let _ = NSFont(name: eachTrimmed, size: 10) {
                    fontFamily = eachTrimmed
                    break
                }
            }
        }
    }

    if fontFamily == "" {
        fontFamily = font.fontName
    }

    if let fontStyle = jsStyle["font-style"] as? String {
        switch fontStyle {
        case "normal":
            fontTraitMask.formUnion(.unitalicFontMask)
        case "italic":
            fontTraitMask.formUnion(.italicFontMask)
        default:
            print("unrecognized font style: \(fontStyle)")
        }
    }

    if let fontWeightString = jsStyle["font-weight"] as? String {
        switch fontWeightString {
        case "normal":
            fontWeight = 5
            fontTraitMask.formUnion(.unboldFontMask)
        case "bold":
            fontWeight = 9
            fontTraitMask.formUnion(.boldFontMask)
        default:
            if let weight = Int(fontWeightString) {
                fontWeight = weight
            } else {
                print("unrecognized font weight: \(fontWeightString)")
            }
        }
    }

    if let size = jsStyle["font-size"] as? NSNumber, size.floatValue > 0 {
        fontSize = CGFloat(size.floatValue)
    }

    return NSFontManager.shared.font(withFamily: fontFamily, traits: fontTraitMask, weight: fontWeight, size: fontSize)
}

func cursorFromJSStyle(_ jsStyle: [String: Any]) -> NSCursor? {
    if let cursor = jsStyle["cursor"] as? String {
        if cursor == "default" {
            return NSCursor.arrow
        } else if cursor == "pointer" {
            return NSCursor.pointingHand
        } else if cursor == "text" {
            return NSCursor.iBeam
        }
    }
    return nil
}

func paragraphStyleFromJSStyle(_ jsStyle: [String: Any]) -> NSParagraphStyle? {
    let paragraphStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle

    if let number = jsStyle["line-height-multiple"] as? NSNumber, number.floatValue > 0 {
        paragraphStyle.lineHeightMultiple = CGFloat(number.floatValue)
    }

    if let number = jsStyle["paragraph-spacing-before"] as? NSNumber, number.floatValue > 0 {
        paragraphStyle.paragraphSpacingBefore = CGFloat(number.floatValue)
    }

    if let number = jsStyle["paragraph-spacing-after"] as? NSNumber, number.floatValue > 0 {
        paragraphStyle.paragraphSpacing = CGFloat(number.floatValue)
    }

    return paragraphStyle
}

public protocol StylesheetHolder {
    var styleSheet: StyleSheet? { get set }
}

extension NSViewController {
    func sendStyleSheetToSelfAndDescendentHolders(_ styleSheet: StyleSheet?) {
        for each in descendentViewControllersWithSelf {
            if var each = each as? StylesheetHolder {
                each.styleSheet = styleSheet
            }
        }
    }
}
