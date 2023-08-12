//
//  BirchOutlineEditor.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 6/28/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa
import JavaScriptCore

public typealias OutlineEditorState = (hoistedItem: ItemType?, focusedItem: ItemType?, itemPathFilter: String?)

public protocol OutlineEditorType: AnyObject, StylesheetHolder {
    var outline: OutlineType { get }
    var outlineSidebar: OutlineSidebarType? { get }

    var textStorage: OutlineEditorTextStorage { get }
    var outlineEditorViewController: OutlineEditorViewController? { get set }

    var selectedRange: NSRange { get set }
    var selectedItems: [ItemType] { get }
    var displayedSelectedItems: [ItemType] { get }
    func moveSelectionToItems(_ headItem: ItemType, headOffset: Int?, anchorItem: ItemType?, anchorOffset: Int?)
    func moveSelectionToRange(_ headLocation: Int, anchorLocation: Int?)
    func focus()

    var hoistedItem: ItemType { get set }
    var focusedItem: ItemType? { get set }
    var itemPathFilter: String { get set }

    var editorState: OutlineEditorState { get set }
    var firstDisplayedItem: ItemType? { get }
    var lastDisplayedItem: ItemType? { get }

    var numberOfDisplayedItems: Int { get }
    var heightOfDisplayedItems: CGFloat { get }

    func displayedItem(at index: Int) -> ItemType
    func displayedItemYOffset(at index: Int) -> CGFloat
    func displayedItemIndexAtYOffset(at yOffset: CGFloat) -> Int
    func setDisplayedItemHeight(_ height: CGFloat, at index: Int)

    func toggleAttribute(_ attribute: String)

    func onDidChangeHoistedItem(_ callback: @escaping () -> Void) -> DisposableType
    func onDidChangeFocusedItem(_ callback: @escaping () -> Void) -> DisposableType
    func onDidChangeItemPathFilter(_ callback: @escaping () -> Void) -> DisposableType

    var restorableState: Any { get set }
    var serializedRestorableState: String { get set }

    func serializeItems(_ items: [ItemType], options: [String: Any]?) -> String
    func serializeRange(_ range: NSRange, options: [String: Any]?) -> String
    func deserializeItems(_ serializedItems: String, options: [String: Any]?) -> [ItemType]?

    func replaceRangeWithString(_ range: NSRange, string: String)
    func replaceRangeWithItems(_ range: NSRange, items: [ItemType])

    func moveBranches(_ items: [ItemType]?, parent: ItemType, nextSibling: ItemType?, options: [String: Any]?)

    func performCommand(_ command: String, options: Any?)
    func evaluateScript(_ script: String, withOptions options: Any?) -> Any?

    var styleSheet: StyleSheet? { get set }
    var computedStyle: ComputedStyle? { get }
    var computedItemIndent: Int { get }
    var mouseOverItem: ItemType? { get set }
    var mouseOverItemHandle: ItemType? { get set }

    func guideRangesForVisibleRange(_ characterRange: NSRange) -> [NSRange]
    func gapLocationsForVisibleRange(_ characterRange: NSRange) -> [Int]

    func clickedOnItem(_ item: ItemType, link: String) -> Bool
    func createPasteboardItem(_ item: ItemType) -> NSPasteboardItem
}

public protocol OutlineEditorHolderType {
    var outlineEditor: OutlineEditorType? { get set }
}

public final class OutlineEditor: NSObject, OutlineEditorType {
    public let outline: OutlineType
    public var outlineSidebar: OutlineSidebarType?
    public let textStorage: OutlineEditorTextStorage
    public weak var outlineEditorViewController: OutlineEditorViewController?
    public var styleSheet: StyleSheet? {
        didSet {
            jsOutlineEditor.setValue(styleSheet?.jsStyleSheet ?? JSValue(undefinedIn: jsOutlineEditor.context)!, forProperty: "styleSheet")
            computedStyle = styleSheet?.computedStyleForElement(jsOutlineEditor.forProperty("editorStyleElement") as Any)
            computedItemIndent = (computedStyle?.allValues[.itemIndent] as? Int) ?? 17
        }
    }

    var jsOutlineEditor: JSValue!
    var styleSheetListener: DisposableType?
    var pasteboardItems = [NSPasteboardItem]()

    public init(outline: OutlineType, styleSheet: StyleSheet, scriptContext: BirchScriptContext) {
        self.outline = outline
        let textStorage = OutlineEditorTextStorage()
        self.textStorage = textStorage
        super.init()
        textStorage.outlineEditor = self

        let jsOutlineEditorClass = scriptContext.jsOutlineEditorClass
        let nativeWrapper = OutlineEditorWeakProxy(outlineEditor: self)

        jsOutlineEditor = jsOutlineEditorClass.construct(withArguments: [(outline as! Outline).jsOutline, styleSheet.jsStyleSheet, nativeWrapper])
        jsOutlineEditorClass.invokeMethod("addOutlineEditor", withArguments: [jsOutlineEditor as Any])

        outlineSidebar = OutlineSidebar(outlineEditor: self, scriptContext: scriptContext)
    }

    deinit {
        outlineSidebar?.destroy()
        textStorage.cleanUp()
        styleSheetListener?.dispose()
        jsOutlineEditor.invokeMethod("destroy", withArguments: [])
    }

    public var selectedRange: NSRange {
        get {
            let jsSelection = jsOutlineEditor.forProperty("selection")
            let location = Int(truncating: (jsSelection?.forProperty("location").toNumber())!)
            let length = Int(truncating: (jsSelection?.forProperty("length").toNumber())!)
            return NSMakeRange(location, length)
        }
        set(range) {
            jsOutlineEditor.invokeMethod("moveSelectionToRange", withArguments: [range.location, range.location + range.length])
        }
    }

    public var selectedItems: [ItemType] {
        return jsOutlineEditor.forProperty("selection").forProperty("selectedItems").toItemTypeArray()
    }

    public var displayedSelectedItems: [ItemType] {
        return jsOutlineEditor.forProperty("selection").forProperty("displayedSelectedItems").toItemTypeArray()
    }

    public func moveSelectionToItems(_ headItem: ItemType, headOffset: Int?, anchorItem: ItemType?, anchorOffset: Int?) {
        let undefined = JSValue(undefinedIn: jsOutlineEditor.context)!
        let ho = headOffset ?? undefined as Any
        let ai = anchorItem ?? undefined as Any
        let ao = anchorOffset ?? undefined as Any

        jsOutlineEditor.invokeMethod("moveSelectionToItems", withArguments: [
            headItem,
            ho,
            ai,
            ao,
        ])
    }

    public func moveSelectionToRange(_ headLocation: Int, anchorLocation: Int?) {
        let undefined = JSValue(undefinedIn: jsOutlineEditor.context)!
        jsOutlineEditor.invokeMethod("moveSelectionToRange", withArguments: [
            headLocation,
            anchorLocation ?? undefined as Any,
        ])
    }

    public func focus() {
        jsOutlineEditor.invokeMethod("focus", withArguments: [])
    }

    public var hoistedItem: ItemType {
        get {
            return jsOutlineEditor.forProperty("hoistedItem")
        }
        set(item) {
            jsOutlineEditor.setValue(item, forProperty: "hoistedItem")
        }
    }

    public var focusedItem: ItemType? {
        get {
            return jsOutlineEditor.forProperty("focusedItem").selfOrNil()
        }
        set(item) {
            jsOutlineEditor.setValue(item, forProperty: "focusedItem")
        }
    }

    public var itemPathFilter: String {
        get {
            return jsOutlineEditor.forProperty("itemPathFilter").toString()
        }
        set(filter) {
            jsOutlineEditor.setValue(filter, forProperty: "itemPathFilter")
        }
    }

    public var editorState: OutlineEditorState {
        get {
            return (hoistedItem: hoistedItem, focusedItem: focusedItem, itemPathFilter: itemPathFilter)
        }
        set(value) {
            let undefined = JSValue(undefinedIn: jsOutlineEditor.context)!
            let hoistedItem = value.hoistedItem ?? undefined
            let focusedItem = value.focusedItem ?? undefined
            let itemPathFilter = value.itemPathFilter ?? undefined as Any
            let editorState = NSDictionary(dictionary: ["hoistedItem": hoistedItem, "focusedItem": focusedItem, "itemPathFilter": itemPathFilter])
            jsOutlineEditor.setValue(editorState, forProperty: "editorState")
        }
    }

    public var firstDisplayedItem: ItemType? {
        return jsOutlineEditor.forProperty("firstDisplayedItem").selfOrNil()
    }

    public var lastDisplayedItem: ItemType? {
        return jsOutlineEditor.forProperty("lastDisplayedItem").selfOrNil()
    }

    public var numberOfDisplayedItems: Int {
        return Int(jsOutlineEditor.forProperty("numberOfDisplayedItems").toInt32())
    }

    public var heightOfDisplayedItems: CGFloat {
        return CGFloat(jsOutlineEditor.forProperty("heightOfDisplayedItems").toDouble())
    }

    public func displayedItem(at index: Int) -> ItemType {
        return jsOutlineEditor.invokeMethod("getDisplayedItemAtIndex", withArguments: [index])
    }

    public func displayedItemYOffset(at index: Int) -> CGFloat {
        return CGFloat(jsOutlineEditor.invokeMethod("getDisplayedItemYOffsetAtIndex", withArguments: [index]).toDouble())
    }

    public func displayedItemIndexAtYOffset(at yOffset: CGFloat) -> Int {
        return Int(jsOutlineEditor.invokeMethod("getDisplayedItemIndexAtYOffset", withArguments: [yOffset]).toInt32())
    }

    public func setDisplayedItemHeight(_ height: CGFloat, at index: Int) {
        jsOutlineEditor.invokeMethod("setDisplayedItemHeightAtIndex", withArguments: [height, index])
    }

    public func toggleAttribute(_ attribute: String) {
        jsOutlineEditor.invokeMethod("toggleAttribute", withArguments: [attribute])
    }

    public func onDidChangeHoistedItem(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsOutlineEditor.invokeMethod("onDidChangeHoistedItem", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    public func onDidChangeFocusedItem(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsOutlineEditor.invokeMethod("onDidChangeFocusedItem", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    public func onDidChangeItemPathFilter(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsOutlineEditor.invokeMethod("onDidChangeItemPathFilter", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    public var restorableState: Any {
        get {
            return jsOutlineEditor.forProperty("restorableState") as Any
        }
        set {
            jsOutlineEditor.setValue(newValue, forProperty: "restorableState")
        }
    }

    public var serializedRestorableState: String {
        get {
            return jsOutlineEditor.forProperty("serializedRestorableState").toString()
        }
        set {
            jsOutlineEditor.setValue(newValue, forProperty: "serializedRestorableState")
        }
    }

    public func serializeItems(_ items: [ItemType], options: [String: Any]?) -> String {
        let mapped: [Any] = items.map { $0 }
        return jsOutlineEditor.invokeMethod("serializeItems", withArguments: [mapped, options as Any]).toString()
    }

    public func serializeRange(_ range: NSRange, options: [String: Any]?) -> String {
        return jsOutlineEditor.invokeMethod("serializeRange", withArguments: [range.location, range.length, options as Any]).toString()
    }

    public func deserializeItems(_ serializedItems: String, options: [String: Any]?) -> [ItemType]? {
        return jsOutlineEditor.invokeMethod("deserializeItems", withArguments: [serializedItems, options as Any])?.selfOrNil()?.toItemTypeArray()
    }

    public func replaceRangeWithString(_ range: NSRange, string: String) {
        jsOutlineEditor.invokeMethod("replaceRangeWithString", withArguments: [range.location, range.length, string])
    }

    public func replaceRangeWithItems(_ range: NSRange, items: [ItemType]) {
        let mapped: [Any] = items.map { $0 }
        jsOutlineEditor.invokeMethod("replaceRangeWithItems", withArguments: [range.location, range.length, mapped])
    }

    public func moveBranches(_ items: [ItemType]?, parent: ItemType, nextSibling: ItemType?, options: [String: Any]?) {
        var jsItems: JSValue = JSValue(undefinedIn: jsOutlineEditor.context)!
        if let items = items {
            jsItems = JSValue.fromItemTypeArray(items, context: jsOutlineEditor.context)
        }
        let jsNextSibling: JSValue = nextSibling as? JSValue ?? JSValue(undefinedIn: jsOutlineEditor.context)!
        jsOutlineEditor.invokeMethod("moveBranches", withArguments: [jsItems, parent, jsNextSibling, options as Any])
    }

    public func performCommand(_ command: String, options: Any? = nil) {
        jsOutlineEditor.invokeMethod("performCommand", withArguments: [command, options as Any])
    }

    public func evaluateScript(_ script: String, withOptions options: Any?) -> Any? {
        guard let outlineEditor = jsOutlineEditor else {
            return nil
        }

        var jsonResult: String

        if let options = options, let jsonOptions = JSONRepresentation(["_wrappedValue": options]) {
            jsonResult = outlineEditor.invokeMethod("evaluateScript", withArguments: [script, jsonOptions]).toString()!
        } else {
            jsonResult = outlineEditor.invokeMethod("evaluateScript", withArguments: [script]).toString()
        }

        if let jsonValue = jsonResult.JSONValue() as? [String: Any] {
            return jsonValue["_wrappedValue"]!
        }

        return nil
    }

    // MARK: - Computed Style

    public var computedStyle: ComputedStyle?
    public var computedItemIndent: Int = 17

    public var mouseOverItem: ItemType? {
        get {
            return jsOutlineEditor.forProperty("mouseOverItem").selfOrNil()
        }
        set(value) {
            jsOutlineEditor.setValue(value ?? JSValue(nullIn: jsOutlineEditor.context), forProperty: "mouseOverItem")
        }
    }

    public var mouseOverItemHandle: ItemType? {
        get {
            return jsOutlineEditor.forProperty("mouseOverItemHandle").selfOrNil()
        }
        set(value) {
            jsOutlineEditor.setValue(value ?? JSValue(nullIn: jsOutlineEditor.context), forProperty: "mouseOverItemHandle")
        }
    }

    public func guideRangesForVisibleRange(_ characterRange: NSRange) -> [NSRange] {
        guard let outlineEditor = jsOutlineEditor else {
            return []
        }

        let guideLocations = outlineEditor.invokeMethod("getGuideRangesForVisibleRange", withArguments: [characterRange.location, characterRange.length]).toArray()
        var guideRanges: [NSRange] = []
        if let guideLocations = guideLocations as? [Int] {
            for i in stride(from: 0, to: guideLocations.count - 1, by: 2) {
                guideRanges.append(NSRange(location: guideLocations[i], length: guideLocations[i + 1]))
            }
        }
        return guideRanges
    }

    public func gapLocationsForVisibleRange(_ characterRange: NSRange) -> [Int] {
        guard let outlineEditor = jsOutlineEditor else {
            return []
        }

        let gapLocations = outlineEditor.invokeMethod("getGapLocationsForVisibleRange", withArguments: [characterRange.location, characterRange.length]).toArray()

        return gapLocations as? [Int] ?? []
    }

    public func clickedOnItem(_ item: ItemType, link: String) -> Bool {
        return jsOutlineEditor.invokeMethod("clickedOnItemLink", withArguments: [item, link]).toBool()
    }

    public func createPasteboardItem(_ item: ItemType) -> NSPasteboardItem {
        let pasteboardItem = NSPasteboardItem()
        let serializedReferences = serializeItems([item], options: ["type": NSPasteboard.PasteboardType.itemReference.rawValue])
        pasteboardItem.setString(serializedReferences, forType: .itemReference)
        pasteboardItem.setDataProvider(ItemPasteboardProvider(item: item, outlineEditor: self), forTypes: ItemPasteboardUtilities.writablePasteboardTypes)
        pasteboardItems.append(pasteboardItem)
        return pasteboardItem
    }
}

extension NSViewController {
    public func sendToOutlineEditorToSelfAndDescendentHolders(_ outlineEditor: OutlineEditorType?) {
        for each in descendentViewControllersWithSelf {
            if var each = each as? OutlineEditorHolderType {
                each.outlineEditor = outlineEditor
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSPasteboardPasteboardType(_ input: String) -> NSPasteboard.PasteboardType {
    return NSPasteboard.PasteboardType(rawValue: input)
}
