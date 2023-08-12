//
//  OutlineViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/27/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

protocol OutlineEditorViewHandleDelegate {
    func outlineEditor(_ outlineEditor: OutlineEditorView, clickedItemHandle: ItemType) -> Bool
}

open class OutlineEditorViewController: NSViewController, OutlineEditorHolderType, StylesheetHolder {
    @IBOutlet var outlineEditorView: OutlineEditorView! // Can't have a weak outlet because NSTextView can't have weak references.
    @IBOutlet var searchToolbarContainerView: NSView!
    @IBOutlet var handleClickGestureRecognizer: NSClickGestureRecognizer!
    @IBOutlet var handleDragGestureRecognizer: NSPanGestureRecognizer!

    var selectionStack: [NSRange] = []

    deinit {
        outlineEditorView?.delegate = nil
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        outlineEditorView.delegate = self
        outlineEditorView.wordRangeLeadExtensionCharacters = CharacterSet(charactersIn: "@")
    }

    override open func viewWillAppear() {
        super.viewWillAppear()
    }
    
    open var outlineEditor: OutlineEditorType? {
        didSet {
            if !isViewLoaded {
                loadView()
            }

            // Otherwise memory leak if close when autocomplete is showing
            outlineEditorView.setSelectedRange(NSMakeRange(0, 0))

            // Just for good measure
            outlineEditorView.inputContext?.discardMarkedText()
            if outlineEditorView.window?.firstResponder === outlineEditorView {
                outlineEditorView.window?.makeFirstResponder(nil)
            }

            // Tear down ... Faster OutlineEditorTextStorage.deinit
            outlineEditorView?.layoutManager?.replaceTextStorage(NSTextStorage())
            outlineEditorView?.textContainer?.replaceLayoutManager(NSLayoutManager())

            // Anytime I call replaceTextContainer I get objc_weak_error Seems internal to cocoa text system
            // not sure if it's a real problem or not.
            if let oldSize = outlineEditorView?.textContainer?.containerSize {
                outlineEditorView?.replaceTextContainer(NSTextContainer(size: oldSize))
            } else {
                outlineEditorView?.replaceTextContainer(NSTextContainer(size: NSZeroSize))
            }

            outlineEditor?.outlineEditorViewController = nil
            outlineEditorView.outlineEditor = nil

            if let textStorage = outlineEditor?.textStorage {
                let textContainer = OutlineEditorTextContainer()
                if let oldTextContainer = outlineEditorView.textContainer {
                    textContainer.containerSize = oldTextContainer.containerSize
                    textContainer.widthTracksTextView = true
                    textContainer.heightTracksTextView = false
                }
                outlineEditorView.replaceTextContainer(textContainer) // causes objc_weak_error

                let layoutManager = OutlineEditorLayoutManager(outlineEditor: outlineEditor!)
                outlineEditorView.textContainer?.replaceLayoutManager(layoutManager)
                outlineEditorView.layoutManager?.replaceTextStorage(textStorage)
                outlineEditor?.outlineEditorViewController = self
                outlineEditorView.outlineEditor = outlineEditor

                if let scrollView = outlineEditorView.enclosingScrollView {
                    scrollView.hasHorizontalScroller = false
                    scrollView.horizontalScrollElasticity = .none
                    scrollView.horizontalLineScroll = 0
                    scrollView.horizontalPageScroll = 0
                    scrollView.hasHorizontalRuler = false
                    scrollView.horizontalRulerView = nil
                }
            }
        }
    }

    open var styleSheet: StyleSheet? {
        didSet {
            outlineEditor?.styleSheet = styleSheet
            if let computedStyle = outlineEditor?.computedStyle {
                if let layoutManager = outlineEditorView.layoutManager as? OutlineEditorLayoutManager {
                    layoutManager.outlineEditorComputedStyle = computedStyle
                    if let textContainer = outlineEditorView.textContainer as? OutlineEditorTextContainer {
                        // Because typesetter expands line fragments to contain invisibles ... so need to make sure there is space
                        // for the expansion otherwise the text view will all of the sudden have to scroll.
                        textContainer.roomForTrailingInvisibles = layoutManager.newlineInvisibleAdvance
                    }
                }

                outlineEditorView.backgroundColor = computedStyle.attributedStringValues[.backgroundColor] as? NSColor ?? NSColor.white
                outlineEditorView.insertionPointColor = computedStyle.allValues[.caretColor] as? NSColor ?? NSColor.black
                outlineEditorView.dropTargetIndicatorColor = computedStyle.allValues[.dropIndicatorColor] as? NSColor ?? NSColor.black
                outlineEditorView.insertionPointWidth = computedStyle.allValues[.caretWidth] as? CGFloat ?? 2
                outlineEditorView.defaultParagraphStyle = computedStyle.attributedStringValues[.paragraphStyle] as? NSParagraphStyle ?? NSParagraphStyle.default
                outlineEditorView.itemIndentPerLevel = CGFloat(outlineEditor?.computedItemIndent ?? 17)
                outlineEditorView.uiScale = computedStyle.allValues[.uiScale] as? CGFloat ?? 1
                outlineEditorView.typingAttributes = computedStyle.attributedStringValues

                outlineEditorView.linkTextAttributes = [:]

                outlineEditor?.textStorage.outlineEditorComputedStyle = computedStyle

                outlineEditorView.editorWrapToColumn = computedStyle.allValues[.editorWrapToColumn] as? Int ?? 0
                outlineEditorView.itemWrapToColumn = computedStyle.allValues[.itemWrapToColumn] as? Int ?? 0

                outlineEditorView.topMarginViewportPaddingPercent = (computedStyle.allValues[.topPaddingPercent] as? CGFloat ?? 0) / 100
                outlineEditorView.bottomMarginViewportPaddingPercent = (computedStyle.allValues[.bottomPaddingPercent] as? CGFloat ?? 0) / 100
                outlineEditorView.typewriterScrollingPercent = (computedStyle.allValues[.typewriterScrollPercent] as? CGFloat ?? 0) / 100

                if let selectionColor = computedStyle.allValues[.selectionBackgroundColor] as? NSColor {
                    outlineEditorView.selectedTextAttributes = [
                        .backgroundColor: selectionColor,
                    ]
                }
            }
        }
    }
}

extension OutlineEditorViewController: NSGestureRecognizerDelegate {
    @IBAction func handleClick(_ sender: NSClickGestureRecognizer) {
        let location = sender.location(in: outlineEditorView)
        if let pick = outlineEditorView.pickItem(location) {
            _ = outlineEditor(outlineEditorView, clickedItemHandle: pick.storageItem.item)
        }
    }

    @IBAction func handleDragStart(_: NSPanGestureRecognizer) {
        if let event = NSApp.currentEvent {
            let location = outlineEditorView.convert(event.locationInWindow, from: nil)
            if let pick = outlineEditorView.pickItem(location), pick.handleContainsPoint {
                outlineEditorView.beginItemHandleDrag(event, pick: pick)
            }
        }
    }

    public func gestureRecognizer(_: NSGestureRecognizer, shouldAttemptToRecognizeWith event: NSEvent) -> Bool {
        let location = outlineEditorView.convert(event.locationInWindow, from: nil)
        let pick = outlineEditorView.pickItem(location)
        if let handleContainsPoint = pick?.handleContainsPoint, handleContainsPoint {
            return true
        }
        return false
    }
}
