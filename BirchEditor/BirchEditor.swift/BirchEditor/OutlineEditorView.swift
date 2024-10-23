//
//  OutlineEditorView.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa
import JavaScriptCore

enum ItemDropLocation {
    case on
    case above
    case below
}

struct StorageItemPick {
    let storageItem: OutlineEditorTextStorageItem
    let characterIndex: Int
    let attributes: [NSAttributedString.Key: Any]
    let itemContainsPoint: Bool
    let handleContainsPoint: Bool
}

struct StorageItemDropTargetPick {
    let storageItemPick: StorageItemPick
    let dropLocation: ItemDropLocation

    var target: ItemType {
        return storageItemPick.storageItem.item
    }

    var parent: ItemType? {
        switch dropLocation {
        case .on:
            return target
        case .above:
            return target.parent
        case .below:
            return target.parent
        }
    }

    var nextSibling: ItemType? {
        switch dropLocation {
        case .on:
            return target.firstChild
        case .above:
            return target
        case .below:
            return target.nextSibling
        }
    }
}

class OutlineEditorView: NSTextView {
    weak var outlineEditor: OutlineEditorType?

    var uiScale: CGFloat = 1
    var itemIndentPerLevel: CGFloat = 20.0 {
        didSet {
            (textContainer as? OutlineEditorTextContainer)?.itemIndentPerLevel = itemIndentPerLevel
        }
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func commonInit() {
        textContainerInset = NSZeroSize

        isContinuousSpellCheckingEnabled = userDefaults.bool(forKey: BCheckSpellingAsYouType)
        isGrammarCheckingEnabled = userDefaults.bool(forKey: BCheckGrammarWithSpelling)
        isAutomaticSpellingCorrectionEnabled = userDefaults.bool(forKey: BCorrectSpellingAutomatically)
        smartInsertDeleteEnabled = userDefaults.bool(forKey: BSmartCopyPaste)
        isAutomaticQuoteSubstitutionEnabled = userDefaults.bool(forKey: BSmartQuotes)
        isAutomaticDashSubstitutionEnabled = userDefaults.bool(forKey: BSmartDashes)
        isAutomaticDataDetectionEnabled = userDefaults.bool(forKey: BDataDetectors)
        isAutomaticTextReplacementEnabled = userDefaults.bool(forKey: BTextReplacement)

        userDefaults.addObserver(self, forKeyPath: BCheckSpellingAsYouType, options: .new, context: nil)
        userDefaults.addObserver(self, forKeyPath: BCheckGrammarWithSpelling, options: .new, context: nil)
        userDefaults.addObserver(self, forKeyPath: BCorrectSpellingAutomatically, options: .new, context: nil)
        userDefaults.addObserver(self, forKeyPath: BSmartCopyPaste, options: .new, context: nil)
        userDefaults.addObserver(self, forKeyPath: BSmartQuotes, options: .new, context: nil)
        userDefaults.addObserver(self, forKeyPath: BSmartDashes, options: .new, context: nil)
        userDefaults.addObserver(self, forKeyPath: BDataDetectors, options: .new, context: nil)
        userDefaults.addObserver(self, forKeyPath: BTextReplacement, options: .new, context: nil)
    }

    deinit {
        userDefaults.removeObserver(self, forKeyPath: BCheckSpellingAsYouType)
        userDefaults.removeObserver(self, forKeyPath: BCheckGrammarWithSpelling)
        userDefaults.removeObserver(self, forKeyPath: BCorrectSpellingAutomatically)
        userDefaults.removeObserver(self, forKeyPath: BSmartCopyPaste)
        userDefaults.removeObserver(self, forKeyPath: BSmartQuotes)
        userDefaults.removeObserver(self, forKeyPath: BSmartDashes)
        userDefaults.removeObserver(self, forKeyPath: BDataDetectors)
        userDefaults.removeObserver(self, forKeyPath: BTextReplacement)
    }

    // MARK: - Shared Settings

    override var isContinuousSpellCheckingEnabled: Bool {
        didSet {
            if isContinuousSpellCheckingEnabled != userDefaults.bool(forKey: BCheckSpellingAsYouType) {
                userDefaults.set(isContinuousSpellCheckingEnabled, forKey: BCheckSpellingAsYouType)
            }
        }
    }

    override var isGrammarCheckingEnabled: Bool {
        didSet {
            if isGrammarCheckingEnabled != userDefaults.bool(forKey: BCheckGrammarWithSpelling) {
                userDefaults.set(isGrammarCheckingEnabled, forKey: BCheckGrammarWithSpelling)
            }
        }
    }

    override var isAutomaticSpellingCorrectionEnabled: Bool {
        didSet {
            if isAutomaticSpellingCorrectionEnabled != userDefaults.bool(forKey: BCorrectSpellingAutomatically) {
                userDefaults.set(isAutomaticSpellingCorrectionEnabled, forKey: BCorrectSpellingAutomatically)
            }
        }
    }

    override var smartInsertDeleteEnabled: Bool {
        didSet {
            if smartInsertDeleteEnabled != userDefaults.bool(forKey: BSmartCopyPaste) {
                userDefaults.set(smartInsertDeleteEnabled, forKey: BSmartCopyPaste)
            }
        }
    }

    override var isAutomaticQuoteSubstitutionEnabled: Bool {
        didSet {
            if isAutomaticQuoteSubstitutionEnabled != userDefaults.bool(forKey: BSmartQuotes) {
                userDefaults.set(isAutomaticQuoteSubstitutionEnabled, forKey: BSmartQuotes)
            }
        }
    }

    override var isAutomaticDashSubstitutionEnabled: Bool {
        didSet {
            if isAutomaticDashSubstitutionEnabled != userDefaults.bool(forKey: BSmartDashes) {
                userDefaults.set(isAutomaticDashSubstitutionEnabled, forKey: BSmartDashes)
            }
        }
    }

    override var isAutomaticDataDetectionEnabled: Bool {
        didSet {
            if isAutomaticDataDetectionEnabled != userDefaults.bool(forKey: BDataDetectors) {
                userDefaults.set(isAutomaticDataDetectionEnabled, forKey: BDataDetectors)
            }
        }
    }

    override var isAutomaticTextReplacementEnabled: Bool {
        didSet {
            if isAutomaticTextReplacementEnabled != userDefaults.bool(forKey: BTextReplacement) {
                userDefaults.set(isAutomaticTextReplacementEnabled, forKey: BTextReplacement)
            }
        }
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == BCheckSpellingAsYouType {
            isContinuousSpellCheckingEnabled = userDefaults.bool(forKey: BCheckSpellingAsYouType)
        } else if keyPath == BCheckGrammarWithSpelling {
            isGrammarCheckingEnabled = userDefaults.bool(forKey: BCheckGrammarWithSpelling)
        } else if keyPath == BCorrectSpellingAutomatically {
            isAutomaticSpellingCorrectionEnabled = userDefaults.bool(forKey: BCorrectSpellingAutomatically)
        } else if keyPath == BSmartCopyPaste {
            smartInsertDeleteEnabled = userDefaults.bool(forKey: BSmartCopyPaste)
        } else if keyPath == BSmartQuotes {
            isAutomaticQuoteSubstitutionEnabled = userDefaults.bool(forKey: BSmartQuotes)
        } else if keyPath == BSmartDashes {
            isAutomaticDashSubstitutionEnabled = userDefaults.bool(forKey: BSmartDashes)
        } else if keyPath == BDataDetectors {
            isAutomaticDataDetectionEnabled = userDefaults.bool(forKey: BDataDetectors)
        } else if keyPath == BTextReplacement {
            isAutomaticTextReplacementEnabled = userDefaults.bool(forKey: BTextReplacement)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    // MARK: - Selection

    override func setSelectedRange(_ charRange: NSRange) {
        super.selectedRange = charRange
    }

    override func setSelectedRanges(_ ranges: [NSValue], affinity: NSSelectionAffinity, stillSelecting stillSelectingFlag: Bool) {
        var constrainedRanges: [NSValue] = []
        for each in ranges {
            var eachRange = each.rangeValue
            if eachRange.length == 0 {
                if eachRange.location > 0, eachRange.location == textStorage!.length {
                    eachRange.location -= 1
                }
            }
            constrainedRanges.append(NSValue(range: eachRange))
        }
        super.setSelectedRanges(constrainedRanges, affinity: affinity, stillSelecting: stillSelectingFlag)
    }

    // MARK: - Typewriter Scrolling

    var typewriterScrollingPercent: CGFloat = 0
    var didInsertText = false

    override func insertText(_ aString: Any, replacementRange: NSRange) {
        let markedText = hasMarkedText()
        let selectedRange = self.selectedRange()

        super.insertText(aString, replacementRange: replacementRange)

        // The issue is some simple replacements cause lots of updates in the text view. For example replacing a
        // \n can cause an outline restructure which will replace lots of text. And all that replacement can
        // move the selection to incorrect location. So this code ensures that the selection is proper after standard
        // replacments. With that said if there's marked text I need to leave things alone. Also I have no idea
        // when replacementRange is ever used, so ignoring that case in case it does something important.
        if !markedText, replacementRange.location == NSNotFound {
            if aString is NSString {
                setSelectedRange(NSMakeRange(selectedRange.location + (aString as AnyObject).length, 0))
            }
        }

        if typewriterScrollingPercent > 0 {
            doTypewriterSrolling()
        }

        didInsertText = true
    }

    override func doCommand(by aSelector: Selector) {
        super.doCommand(by: aSelector)

        if typewriterScrollingPercent > 0 {
            let string = NSStringFromSelector(aSelector) as NSString
            if string.range(of: "insert").location == 0 || string.range(of: "delete").location == 0 {
                doTypewriterSrolling()
            }
        }
    }

    func doTypewriterSrolling() {
        guard let clipView = enclosingScrollView?.contentView else {
            return
        }

        let newScrollPoint = scrollPointForTypewriterScrolling()
        if !NSEqualPoints(newScrollPoint, clipView.bounds.origin) {
            NSAnimationContext.beginGrouping()
            clipView.animator().setBoundsOrigin(newScrollPoint)
            NSAnimationContext.endGrouping()
        }
    }

    func scrollPointForTypewriterScrolling() -> NSPoint {
        guard let scrollView = enclosingScrollView else {
            return NSZeroPoint
        }

        let selectedRange = self.selectedRange()
        var scrollPoint = NSZeroPoint

        if selectedRange.location > 0 {
            let contentSize = convert(scrollView.contentSize, from: scrollView)
            let selectionRect = rectForRange(selectedRange)
            scrollPoint = NSMakePoint(NSMinX(selectionRect), NSMidY(selectionRect) - round(contentSize.height * typewriterScrollingPercent))
        } else {
            scrollPoint = NSMakePoint(0, -frame.origin.y)
        }

        scrollPoint.x = round(scrollPoint.x)
        scrollPoint.y = round(scrollPoint.y)

        return scrollPoint
    }

    // MARK: - Wrap to Column

    var editorWrapToColumn: Int = 0 {
        didSet {
            let testString = NSAttributedString(string: "abcdefghijklmnopqrstuvwxyz", attributes: typingAttributes)
            let size = testString.size()
            let width = Int(ceil(size.width / 27.0)) * editorWrapToColumn
            editorWrapToWidth = width
        }
    }

    var editorWrapToWidth: Int = 0 {
        didSet {
            if editorWrapToWidth != oldValue {
                if editorWrapToWidth == 0 {
                    textContainerInset = NSZeroSize
                }
                invalidateAndForceLayout()
            }
        }
    }

    var itemWrapToColumn: Int = 0 {
        didSet {
            let testString = NSAttributedString(string: "abcdefghijklmnopqrstuvwxyz", attributes: typingAttributes)
            let size = testString.size()
            let width = ceil(size.width / 27.0) * CGFloat(itemWrapToColumn)
            itemWrapToWidth = width
        }
    }

    var itemWrapToWidth: CGFloat = 0 {
        didSet {
            if itemWrapToWidth != oldValue {
                (textContainer as? OutlineEditorTextContainer)?.itemTextWrapWidth = itemWrapToWidth
                invalidateAndForceLayout()
            }
        }
    }

    // MARK: - Padding Percents

    var topMarginViewportPaddingPercent: CGFloat = 0 {
        didSet {
            if topMarginViewportPaddingPercent != oldValue {
                invalidateAndForceLayout()
            }
        }
    }

    var bottomMarginViewportPaddingPercent: CGFloat = 0 {
        didSet {
            if bottomMarginViewportPaddingPercent != oldValue {
                invalidateAndForceLayout()
            }
        }
    }

    // MARK: - Layout

    var originOffset = NSZeroPoint
    var minSideMargin: CGFloat = 0
    var lastContentHeight: CGFloat = 0
    var forceProcessSetFrame: Bool = false

    func invalidateAndForceLayout() {
        invalidateTextContainerOrigin()
        layoutManager?.invalidateLayout(forCharacterRange: NSMakeRange(0, textStorage?.length ?? 0), actualCharacterRange: nil)
        forceProcessSetFrame = true
        frame = NSInsetRect(frame, 0, 0)
    }

    override var textContainerOrigin: NSPoint {
        var origin = super.textContainerOrigin
        origin.x += originOffset.x
        origin.y = originOffset.y
        return origin
    }

    override func viewDidEndLiveResize() {
        // http://indiestack.com/2015/04/scrolling-text-view-workarounds/
        // Fix vertical scroll jump after resize.
        let originalInset = textContainerInset
        textContainerInset = NSZeroSize
        super.viewDidEndLiveResize()
        textContainerInset = originalInset
    }

    override var frame: NSRect {
        get {
            return super.frame
        }

        set(newValue) {
            guard let contentHeight = enclosingScrollView?.contentSize.height else {
                super.frame = newValue
                return
            }

            let newFrame = NSIntegralRect(newValue)
            let oldTextContainerInset = textContainerInset
            var newTextContainerInset = textContainerInset

            if forceProcessSetFrame || !NSEqualRects(newFrame, frame) || contentHeight != lastContentHeight {
                forceProcessSetFrame = false

                var topMargin: CGFloat = 0
                var bottomMargin: CGFloat = 0
                var sideMarginActual: CGFloat = 0

                if topMarginViewportPaddingPercent != 0 {
                    topMargin += contentHeight * topMarginViewportPaddingPercent
                }

                if bottomMarginViewportPaddingPercent != 0 {
                    bottomMargin += contentHeight * bottomMarginViewportPaddingPercent
                }

                if editorWrapToWidth != 0 {
                    let sideMarginIdeal = contentHeight * 0.25
                    sideMarginActual = max(minSideMargin, (newFrame.size.width - CGFloat(editorWrapToWidth)) / 2.0)
                    let sideMarginRatio = sideMarginActual / sideMarginIdeal

                    if sideMarginRatio < 1 {
                        topMargin *= sideMarginRatio
                    }
                }

                newTextContainerInset = NSMakeSize(round(sideMarginActual), round((topMargin + bottomMargin + itemIndentPerLevel) / 2.0))
                let newContainerWidth = newFrame.size.width - (2 * newTextContainerInset.width)

                if newContainerWidth.truncatingRemainder(dividingBy: 1) == 0 {
                    newTextContainerInset.width -= 0.5
                }

                if newTextContainerInset.width < 0 {
                    newTextContainerInset.width = 0
                }

                originOffset.y = round(topMargin + itemIndentPerLevel / 2.0)
                lastContentHeight = contentHeight
            }

            super.frame = newValue

            if !NSEqualSizes(oldTextContainerInset, newTextContainerInset) {
                textContainerInset = newTextContainerInset
                invalidateTextContainerOrigin()
            }
        }
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        if let textStorage = textStorage as? OutlineEditorTextStorage {
            assert(!textStorage.isEditing, "TextView should not draw while OutlineEditorTextStorage is editing")
        }

        super.draw(dirtyRect)

        if let dropTargetIndicator = dropTargetIndicator, dropTargetIndicator.bounds.intersects(dirtyRect) {
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(rect: bounds).setClip()
            dropTargetIndicatorColor.set()
            dropTargetIndicator.stroke()
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    // MARK: - Actions

    @IBAction override func changeFont(_ sender: Any?) {
        if isRichText {
            super.changeFont(sender)
        }
    }

    @IBAction override func changeAttributes(_ sender: Any?) {
        if isRichText {
            super.changeAttributes(sender)
        }
    }

    @IBAction override func changeColor(_ sender: Any?) {
        if isRichText {
            super.changeColor(sender)
        }
    }

    @IBAction override func changeDocumentBackgroundColor(_ sender: Any?) {
        if isRichText {
            super.changeDocumentBackgroundColor(sender)
        }
    }

    @IBAction override func moveToBeginningOfDocument(_ sender: Any?) {
        checkTextInVisibleRect()
        super.moveToBeginningOfDocument(sender)
    }

    @IBAction override func moveToEndOfDocument(_ sender: Any?) {
        checkTextInVisibleRect()
        super.moveToEndOfDocument(sender)
    }

    func checkTextInVisibleRect() {
        if let lm = layoutManager, let tc = textContainer, let sv = enclosingScrollView {
            let glyphRange = lm.glyphRange(forBoundingRect: sv.documentVisibleRect, in: tc)
            let characterRange = lm.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            checkText(in: characterRange, types: enabledTextCheckingTypes, options: [:])
        }
    }

    override func validateUserInterfaceItem(_ anItem: NSValidatedUserInterfaceItem) -> Bool {
        if !isRichText {
            if let action = anItem.action {
                switch action {
                case #selector(OutlineEditorView.changeFont): return false
                case #selector(OutlineEditorView.changeAttributes): return false
                case #selector(OutlineEditorView.changeColor): return false
                case #selector(OutlineEditorView.changeDocumentBackgroundColor): return false
                default: return super.validateUserInterfaceItem(anItem)
                }
            }
        }
        return super.validateUserInterfaceItem(anItem)
    }

    // MARK: - Tracking Areas

    var trackingArea: NSTrackingArea?

    override func updateTrackingAreas() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }

        trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .mouseMoved, .cursorUpdate, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil)

        addTrackingArea(trackingArea!)
    }

    override func addTrackingArea(_ trackingArea: NSTrackingArea) {
        super.addTrackingArea(trackingArea)
    }

    override func cursorUpdate(with event: NSEvent) {
        let localPoint = convert(event.locationInWindow, from: nil)

        guard let itemPick = pickItem(localPoint) else {
            NSCursor.iBeam.set()
            return
        }

        if itemPick.handleContainsPoint {
            NSCursor.arrow.set()
            return
        }

        var effectiveRange = NSRange()

        let tempCursor = layoutManager?.temporaryAttribute(NSAttributedString.Key.cursor, atCharacterIndex: itemPick.characterIndex, effectiveRange: &effectiveRange) as? NSCursor
        if let cursor = tempCursor, characterRangeRect(effectiveRange, containsPoint: localPoint) {
            cursor.set()
            return
        }

        let cursor = textStorage?.attribute(NSAttributedString.Key.cursor, at: itemPick.characterIndex, effectiveRange: &effectiveRange) as? NSCursor
        if let cursor = cursor, characterRangeRect(effectiveRange, containsPoint: localPoint) {
            cursor.set()
            return
        }

        NSCursor.iBeam.set()
    }

    // override func hitTest(aPoint: NSPoint) -> NSView? {
    //    return nil
    // }

    override func hitTest(_ aPoint: NSPoint) -> NSView? {
        if visibleRect.contains(aPoint) {
            return super.hitTest(aPoint)
        }
        return nil
    }

    override var visibleRect: NSRect {
        let rect = super.visibleRect
        // rect.origin.y += 22
        // rect.size.height -= 22
        return rect
    }

    // MARK: - Disable Old Forms Of Tracking

    override func addTrackingRect(_: NSRect, owner _: Any, userData _: UnsafeMutableRawPointer?, assumeInside _: Bool) -> NSView.TrackingRectTag {
        Swift.print("BAD addTrackingRect called")
        return -1
    }

    override func addCursorRect(_: NSRect, cursor _: NSCursor) {
        Swift.print("BAD addCursorRect called")
    }

    // MARK: - Menu

    override func menu(for event: NSEvent) -> NSMenu? {
        /* if let _ = outlineEditor?.mouseOverItemHandle {
             let menu = NSMenu(title: "")
             menu.addItem(withTitle: "Cut".localized(), action: #selector(cut(_:)), keyEquivalent: "")
             menu.addItem(withTitle: "Copy".localized(), action: #selector(copy(_:)), keyEquivalent: "")
             menu.addItem(withTitle: "Paste".localized(), action: #selector(paste(_:)), keyEquivalent: "")
             return menu
         } */

        let menu = super.menu(for: event)

        if let removeItem = menu?.submenuItem(withAction: NSSelectorFromString("orderFrontColorPanel:"))?.parent {
            removeItem.menu?.removeItem(removeItem)
        }
        if let removeItem = menu?.submenuItem(withAction: #selector(changeLayoutOrientation))?.parent {
            removeItem.menu?.removeItem(removeItem)
        }
        return menu
    }

    // MARK: - Events

    override func keyDown(with theEvent: NSEvent) {
        didInsertText = false
        super.keyDown(with: theEvent)
        if didInsertText {
            if !hasMarkedText(), userDefaults.bool(forKey: BAutocompleteTagsAsYouType) {
                let range = rangeForUserCompletion
                if range.location != NSNotFound, textStorage!.substring(with: range).hasPrefix("@") {
                    complete(nil)
                }
            }
        }
        outlineEditor?.mouseOverItem = nil
    }

    func pickItem(_ localPoint: NSPoint) -> StorageItemPick? {
        let characterIndex = characterIndexForLocalPoint(localPoint, partialFraction: nil)
        if let textStorage = textStorage as? OutlineEditorTextStorage, characterIndex < textStorage.length {
            if let storageItem = textStorage.storageItemAtIndex(characterIndex) {
                let attributes = textStorage.attributes(at: characterIndex, effectiveRange: nil)
                let layoutManagerPoint = localPoint.pointByTranslating(textContainerOrigin.pointByNegation())
                let geometry = storageItem.itemGeometry(layoutManager!)
                let handleContainsPoint = geometry.handleRect.contains(layoutManagerPoint) && storageItem.itemComputedStyle?.allValues[.handleSize] != nil
                let itemContainsPoint = NSMinY(geometry.itemRect) <= layoutManagerPoint.y && NSMaxY(geometry.itemRect) >= layoutManagerPoint.y
                
                return StorageItemPick(storageItem: storageItem, characterIndex: characterIndex, attributes: attributes, itemContainsPoint: itemContainsPoint, handleContainsPoint: handleContainsPoint)
            }
        }
        return nil
    }

    override func mouseMoved(with theEvent: NSEvent) {
        guard let outlineEditor = outlineEditor else {
            return
        }

        cursorUpdate(with: theEvent)
        if let itemPick = pickItem(convert(theEvent.locationInWindow, from: nil)), itemPick.itemContainsPoint {
            outlineEditor.mouseOverItem = itemPick.storageItem.item
            if itemPick.handleContainsPoint {
                outlineEditor.mouseOverItemHandle = itemPick.storageItem.item
            } else {
                outlineEditor.mouseOverItemHandle = nil
            }
        } else {
            outlineEditor.mouseOverItem = nil
            outlineEditor.mouseOverItemHandle = nil
        }
    }

    override func mouseExited(with _: NSEvent) {
        outlineEditor?.mouseOverItem = nil
        outlineEditor?.mouseOverItemHandle = nil
    }

    override func mouseDown(with theEvent: NSEvent) {
        let localPoint = convert(theEvent.locationInWindow, from: nil)

        guard let itemPick = pickItem(localPoint) else {
            super.mouseDown(with: theEvent)
            return
        }

        if itemPick.handleContainsPoint {
            return
        }

        var effectiveRange = NSRange()
        
        let link =
            textStorage?.attribute(NSAttributedString.Key.link, at: itemPick.characterIndex, effectiveRange: &effectiveRange) ??
            textStorage?.attribute(.toggleDoneInternalLink, at: itemPick.characterIndex, effectiveRange: &effectiveRange) ??
            textStorage?.attribute(.filterInternalLink, at: itemPick.characterIndex, effectiveRange: &effectiveRange)

        if let link = link, characterRangeRect(effectiveRange, containsPoint: localPoint) {
            if let delegate = delegate {
                if delegate.textView!(self, clickedOnLink: link, at: itemPick.characterIndex) {
                    return
                }
            }
        }

        super.mouseDown(with: theEvent)
    }

    // MARK: - Drag Source

    var mouseHandleDraggedStorageItemPick: StorageItemPick?

    override func shouldDelayWindowOrdering(for theEvent: NSEvent) -> Bool {
        return pickItem(convert(theEvent.locationInWindow, from: nil))?.handleContainsPoint ?? super.shouldDelayWindowOrdering(for: theEvent)
    }

    func beginItemHandleDrag(_ theEvent: NSEvent, pick: StorageItemPick) {
        guard let layoutManager = layoutManager as? OutlineEditorLayoutManager, let outlineEditor = outlineEditor else {
            return
        }

        mouseHandleDraggedStorageItemPick = pick

        let pasteboardItem = outlineEditor.createPasteboardItem(mouseHandleDraggedStorageItemPick!.storageItem.item)
        let dragSnapshot = mouseHandleDraggedStorageItemPick!.storageItem.itemBranchSnapshot(layoutManager)
        let dragItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        dragItem.setDraggingFrame(dragSnapshot.bounds.rectByTranslating(textContainerOrigin), contents: dragSnapshot.image)

        let draggingSession = beginDraggingSession(with: [dragItem], event: theEvent, source: self)
        draggingSession.animatesToStartingPositionsOnCancelOrFail = true
        draggingSession.draggingFormation = .none

        NSApp.preventWindowOrdering()
    }

    override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        guard let types = session.draggingPasteboard.types else {
            return NSDragOperation()
        }

        if types.contains(.itemReference) {
            switch context {
            case .withinApplication:
                return [.copy, .move, .delete]
            case .outsideApplication:
                return [.copy, .delete]
            @unknown default:
                assert(false)
                return []
            }
        } else {
            return .generic
        }
    }

    override func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        super.draggingSession(session, endedAt: screenPoint, operation: operation)
        if operation.contains(.delete) {
            if let draggedRefernces = NSPasteboard(name: .drag).string(forType: .itemReference) {
                if let items = outlineEditor?.deserializeItems(draggedRefernces, options: ["type": NSPasteboard.PasteboardType.itemReference.rawValue]) {
                    let jsItems = JSValue.fromItemTypeArray(items, context: (outlineEditor as! OutlineEditor).jsOutlineEditor.context)
                    outlineEditor?.performCommand("outline-editor:delete-branches", options: ["items": jsItems])
                }
            }
        }
        mouseHandleDraggedStorageItemPick = nil
        session.draggingPasteboard.clearContents()
    }

    // MARK: - Drag Destination

    func pickItemDropTarget(_ dragInfo: NSDraggingInfo) -> StorageItemDropTargetPick? {
        let localPoint = convert(dragInfo.draggingLocation, from: nil)

        guard let currentEvent = NSApp.currentEvent else {
            return nil
        }

        guard let itemPick = pickItem(localPoint) else {
            return nil
        }

        let geometry = itemPick.storageItem.itemGeometry(layoutManager!)
        let itemBounds = geometry.itemRect.rectByTranslating(textContainerOrigin)

        if currentEvent.modifierFlags.contains(.shift) {
            return StorageItemDropTargetPick(storageItemPick: itemPick, dropLocation: .on)
        } else {
            if localPoint.y < NSMidY(itemBounds) {
                return StorageItemDropTargetPick(storageItemPick: itemPick, dropLocation: .above)
            } else {
                return StorageItemDropTargetPick(storageItemPick: itemPick, dropLocation: .below)
            }
        }
    }

    override func dragOperation(for dragInfo: NSDraggingInfo, type: NSPasteboard.PasteboardType) -> NSDragOperation {
        let pasteboard = dragInfo.draggingPasteboard

        guard let types = pasteboard.types else {
            return super.dragOperation(for: dragInfo, type: type)
        }

        if !types.contains(.itemReference) {
            return super.dragOperation(for: dragInfo, type: type)
        }

        guard let itemDropPick = pickItemDropTarget(dragInfo), let outlineEditor = outlineEditor else {
            dropTargetStorageItemPick = nil
            return NSDragOperation()
        }

        let dragOperation = ItemPasteboardUtilities.itemsDragOperationForDraggingInfo(dragInfo, editor: outlineEditor, parent: itemDropPick.parent, nextSibling: itemDropPick.nextSibling)
        if dragOperation == [] {
            dropTargetStorageItemPick = nil
        } else {
            dropTargetStorageItemPick = itemDropPick
        }

        return dragOperation
    }

    override func draggingExited(_: NSDraggingInfo?) {
        dropTargetStorageItemPick = nil
    }

    override func draggingEnded(_: NSDraggingInfo) {
        dropTargetStorageItemPick = nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        guard let types = pasteboard.types else {
            return super.performDragOperation(sender)
        }

        if !types.contains(.itemReference) {
            return super.performDragOperation(sender)
        }

        guard let itemDropPick = pickItemDropTarget(sender), let outlineEditor = outlineEditor else {
            return false
        }

        guard let parent = itemDropPick.parent else {
            return false
        }

        return ItemPasteboardUtilities.itemsPerformDragOperation(sender, editor: outlineEditor, parent: parent, nextSibling: itemDropPick.nextSibling)
    }

    var dropTargetIndicatorColor: NSColor = NSColor.black {
        didSet {}
    }

    var dropTargetIndicator: NSBezierPath? {
        willSet {
            if let dropTargetIndicator = dropTargetIndicator {
                setNeedsDisplay(dropTargetIndicator.bounds.insetBy(dx: -dropTargetIndicator.lineWidth, dy: -dropTargetIndicator.lineWidth))
            }
        }
        didSet {
            if let dropTargetIndicator = dropTargetIndicator {
                setNeedsDisplay(dropTargetIndicator.bounds.insetBy(dx: -dropTargetIndicator.lineWidth, dy: -dropTargetIndicator.lineWidth))
            }
        }
    }

    var dropTargetStorageItemPick: StorageItemDropTargetPick? {
        didSet {
            dropTargetIndicator = nil

            if let dropTargetPick = dropTargetStorageItemPick {
                let geometry = dropTargetPick.storageItemPick.storageItem.itemGeometry(layoutManager!)
                var dropTargetIndicatorRect = centerScanRect(geometry.itemUsedRect.rectByTranslating(textContainerOrigin))

                switch dropTargetPick.dropLocation {
                case .on:
                    break
                case .above:
                    dropTargetIndicatorRect.size.height = NSMinY(dropTargetIndicatorRect)
                case .below:
                    dropTargetIndicatorRect.origin.y = NSMaxY(dropTargetIndicatorRect)
                    dropTargetIndicatorRect.size.height = 0
                }

                let nextDropTargetIndicator = NSBezierPath()
                nextDropTargetIndicator.lineWidth = 2.0 * uiScale

                switch dropTargetPick.dropLocation {
                case .on:
                    dropTargetIndicatorRect.origin.x -= itemIndentPerLevel
                    dropTargetIndicatorRect.size.width += itemIndentPerLevel * 1.5
                    nextDropTargetIndicator.appendRoundedRect(dropTargetIndicatorRect, xRadius: 3 * uiScale, yRadius: 3 * uiScale)
                case .above, .below:
                    let circleRadius = 3 * uiScale
                    dropTargetIndicatorRect.origin.x -= (itemIndentPerLevel / 4)
                    dropTargetIndicatorRect.origin.x += (circleRadius * 2)

                    let origin = dropTargetIndicatorRect.origin
                    nextDropTargetIndicator.move(to: origin)
                    nextDropTargetIndicator.line(to: NSMakePoint(NSMaxX(bounds) - textContainerInset.width, origin.y))

                    let circleRect = NSMakeRect(origin.x - circleRadius, origin.y, 0, 0).insetBy(dx: -circleRadius, dy: -circleRadius)
                    nextDropTargetIndicator.appendOval(in: circleRect)
                }

                dropTargetIndicator = nextDropTargetIndicator
            }
        }
    }

    // MARK: - Pasteboard

    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        return ItemPasteboardUtilities.readablePasteboardTypes
    }

    override var writablePasteboardTypes: [NSPasteboard.PasteboardType] {
        if selectedRange.length > 0 {
            return ItemPasteboardUtilities.writablePasteboardTypes
        } else {
            return []
        }
    }

    override var acceptableDragTypes: [NSPasteboard.PasteboardType] {
        return readablePasteboardTypes
    }

    override func readSelection(from pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        if let outlineEditor = outlineEditor, let items = ItemPasteboardUtilities.readItemsFromPasteboard(pboard, type: type, editor: outlineEditor) {
            outlineEditor.replaceRangeWithItems(rangeForUserTextChange, items: items)
            return true
        } else {
            return false
        }
    }

    override func writeSelection(to pboard: NSPasteboard, type: NSPasteboard.PasteboardType) -> Bool {
        return writeSelectionToPasteboard(pboard, type: type, onlyDisplayed: false)
    }

    func writeSelectionToPasteboard(_ pboard: NSPasteboard, type: NSPasteboard.PasteboardType, onlyDisplayed: Bool) -> Bool {
        let options: [String: Any] = ["type": type, "onlyDisplayed": onlyDisplayed]
        let serializedItems = outlineEditor!.serializeRange(selectedRange, options: options)
        pboard.setString(serializedItems, forType: type)
        return true
    }
}
