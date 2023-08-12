//
//  BirchEditor.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 6/28/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

open class BirchEditor {
    public static var semanticVersion: [Int] {
        let shortVersionString = Bundle(for: BirchOutline.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let components = shortVersionString.components(separatedBy: ".")
        return components.map { Int($0)! }
    }

    public static var build: Int {
        return Int(Bundle(for: BirchOutline.self).object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String)!
    }

    public static func createOutline(_ type: String?, content: String?) -> OutlineType {
        return BirchOutline.sharedContext.createOutline(type, content: content)
    }

    public static func createTaskPaperOutline(_ content: String?) -> OutlineType {
        return BirchOutline.sharedContext.createTaskPaperOutline(content)
    }

    public static func createWriteRoomOutline(_ content: String?) -> OutlineType {
        return BirchOutline.sharedContext.createWriteRoomOutline(content)
    }

    public static func createStyleSheet(_ source: URL?) -> StyleSheet {
        return StyleSheet(source: source, scriptContext: BirchOutline.sharedContext)
    }

    public static func createOutlineEditor(_ outline: OutlineType, styleSheet: StyleSheet? = nil) -> OutlineEditorType {
        return OutlineEditor(outline: outline, styleSheet: styleSheet ?? StyleSheet.sharedInstance, scriptContext: BirchOutline.sharedContext)
    }

    public static func syntaxHighlightItemPath(_ attributedString: NSMutableAttributedString, textColor: NSColor, secondaryTextColor: NSColor, errorTextColor: NSColor) {
        guard attributedString.length > 0 else {
            return
        }

        let jsItemPathClass = BirchOutline.sharedContext.jsBirchExports.forProperty("ItemPath")
        let parseInfo = jsItemPathClass!.invokeMethod("parse", withArguments: [attributedString.string]).toDictionary() as NSDictionary
        let keywords = parseInfo["keywords"] as! [[String: Any]]
        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 0),
            .foregroundColor: textColor,
        ]

        attributedString.beginEditing()
        attributedString.setAttributes(defaultAttributes, range: NSMakeRange(0, attributedString.length))

        for each in keywords {
            let offset = each["offset"] as! Int
            let label = each["label"] as! String
            let text = each["text"] as! String
            let range = NSMakeRange(offset, text.utf16.count)

            switch label {
            case "keyword.set", "keyword.boolean":
                attributedString.addAttribute(.foregroundColor, value: secondaryTextColor, range: range)
            case "keyword.operator.relation",
                 "keyword.operator.modifier":
                attributedString.addAttribute(.foregroundColor, value: secondaryTextColor, range: range)
            case "string.quoted",
                 "string.unquoted":
                break
            case "entity.other.axis":
                attributedString.addAttribute(.foregroundColor, value: secondaryTextColor, range: range)
            case "entity.other.tag",
                 "entity.other.attribute-name":
                break
            default:
                break
            }
        }

        if let errorOffset = parseInfo.value(forKeyPath: "error.location.start.offset") as? Int {
            attributedString.addAttribute(.foregroundColor, value: errorTextColor, range: NSMakeRange(errorOffset, attributedString.length - errorOffset))
        }

        attributedString.endEditing()
    }
}
