//
//  OutlineEditorTextStorage.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/5/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

import BirchOutline
import JavaScriptCore

open class OutlineEditorTextStorage: NSTextStorageBase {
    open weak var outlineEditor: OutlineEditor?

    var isEditingCount: UInt = 0
    var isUpdatingNativeCount: UInt = 0
    var idsToStorageItems: [String: OutlineEditorTextStorageItem] = [:]
    var unnormalizedLineEnding = try! NSRegularExpression(pattern: "\\r\\n?|[\\f\\u2B7F\\u2029]", options: [])

    override public init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didProcessEditing),
            name: NSTextStorage.didProcessEditingNotification,
            object: self
        )
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public required init?(pasteboardPropertyList _: Any, ofType _: NSPasteboard.PasteboardType) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }

    func cleanUp() {
        // Use this cleanup method because any reference to self in deinit breaks deinit
        NotificationCenter.default.removeObserver(self)
    }

    deinit {
        // let _ = self
        // For some reason any reference to self here and Allocations Instrument reports this object and all objects that it retains are still alove in memory.
        // NotificationCenter.defaultCenter().removeObserver(self)
    }

    // MARK: - String

    var isUpdatingFromJS: Bool {
        if let jsBool = outlineEditor?.jsOutlineEditor?.forProperty("isUpdatingNativeBuffer") {
            return jsBool.toBool()
        }
        return true
    }

    override open func replaceCharacters(in range: NSRange, with str: String) {
        var insertString = str as NSString

        // Make sure line endings are consistent between cocoa and javascript models. unnormalizedLineEnding
        // should correspond to item-serializer.lineBreakRegex on the JavaScript side, minus '\n' which is what
        // the standardized line ending in Birch should be.
        assert(unnormalizedLineEnding.firstMatch(in: str, options: [], range: NSMakeRange(0, insertString.length)) == nil)

        let updatingFromJS = isUpdatingFromJS
        if !updatingFromJS {
            if NSMaxRange(range) == self.length {
                // Hack to keep in sync with itemBuffer which does the same thing so that
                // it's always ensured that items end with a newline.
                insertString = "\(insertString)\n" as NSString
            }
        }

        let length = insertString.length
        let changeInLength = length - range.length

        enumerateParagraphRanges(in: paragraphRange(for: range)) { enclosingRange, _ in
            if let id = self.backingStorage.attribute(.storageItemIDAttributeName, at: enclosingRange.location, effectiveRange: nil) as? String {
                self.idsToStorageItems.removeValue(forKey: id)
            }
        }

        beginEditing()
        backingStorage.replaceCharacters(in: range, with: insertString as String)
        edited(.editedCharacters, range: range, changeInLength: changeInLength)
        if !updatingFromJS {
            isUpdatingNativeCount += 1
            _ = outlineEditor?.jsOutlineEditor.invokeMethod("replaceRangeWithString", withArguments: [range.location, range.length, str, true])
            isUpdatingNativeCount -= 1
        }
        endEditing()
    }

    // MARK: - Attributes

    @objc func fillBackingStoreAttributesInRange(_ range: NSRange) {
        var paragraphRanges = [NSRange]()

        enumerateParagraphRanges(in: range) { enclosingRange, _ in
            paragraphRanges.append(enclosingRange)
        }

        let storeItems = storageItemsInRange(NSUnionRange(paragraphRanges.first!, paragraphRanges.last!))

        backingStorage.beginEditing()
        for (index, eachRange) in paragraphRanges.enumerated() {
            storeItems[index].renderIntoAttributedString(backingStorage, atItemRange: eachRange)
        }
        backingStorage.endEditing()
    }

    override open func invalidateAttributes(in range: NSRange) {
        backingStorage.invalidateAttributes(in: paragraphRange(for: range))
    }

    override open func ensureAttributesAreFixed(in range: NSRange) {
        backingStorage.ensureAttributesAreFixed(in: range)
    }

    override open func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        backingStorage.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    override open func addAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange) {
        backingStorage.addAttribute(name, value: value, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    override open func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
        backingStorage.addAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }

    override open var fixesAttributesLazily: Bool {
        return backingStorage.fixesAttributesLazily
    }

    // MARK: - Updates

    var isEditing: Bool {
        return isEditingCount > 0
    }

    var isUpdatingNative: Bool {
        return isUpdatingNativeCount > 0
    }

    override open func beginEditing() {
        isEditingCount += 1
        super.beginEditing()
        backingStorage.beginEditing()
        outlineEditor?.outline.beginUndoGrouping()
    }

    override open func endEditing() {
        isEditingCount -= 1
        backingStorage.endEditing()
        super.endEditing()
        outlineEditor?.outline.endUndoGrouping()
    }

    // MARK: - Util

    var outlineEditorComputedStyle: ComputedStyle? {
        didSet {
            clearComputedAttributesInRange(nil)
        }
    }

    func clearComputedAttributesInRange(_ range: NSRange?) {
        let r = range ?? NSMakeRange(0, length)
        invalidateItemsInRange(r)
        if let attributes = outlineEditorComputedStyle?.inheritedAttributedStringValues {
            beginEditing()
            setAttributes(attributes, range: r)
            endEditing()
        }
    }

    @objc func didProcessEditing(_: Notification) {
        if editedMask.contains(.editedCharacters) {
            var range = editedRange
            if NSMaxRange(range) < length { range.length += 1 }
            clearComputedAttributesInRange(paragraphRange(for: range))
        }
    }
}
