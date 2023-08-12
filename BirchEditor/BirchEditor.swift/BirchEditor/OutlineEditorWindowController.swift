//
//  OutlineEditorWindowController.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/1/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

let DocumentWindowFrameAutosaveName = "DocumentWindowFrameAutosaveName"

open class OutlineEditorWindowController: NSWindowController, OutlineEditorHolderType {
    var pathMonitor: PathMonitor?
    var styleSheetUpdateDebouncer: Debouncer?
    var sidebarSelectionDisposable: DisposableType?
    var outlineEditorSerializedRestorableState: String?
    // var showTitlebarDebouncer: Debouncer?
    // var hideTitlebarDebouncer: Debouncer?

    open var styleSheet: StyleSheet? = StyleSheet.sharedInstance {
        didSet {
            pathMonitor?.stopMonitoring()
            pathMonitor = nil

            styleSheetUpdateDebouncer?.cancel()
            styleSheetUpdateDebouncer = nil

            if let styleSheet = styleSheet {
                styleSheetUpdateDebouncer = Debouncer(delay: 0.1) { [weak self] in
                    if let pathMonitor = self?.pathMonitor {
                        self?.styleSheet = BirchEditor.createStyleSheet(pathMonitor.URL)
                    }
                }

                if FileManager.default.fileExists(atPath: styleSheet.source.path) {
                    pathMonitor = PathMonitor(URL: styleSheet.source, callback: { [weak self] in
                        DispatchQueue.main.async {
                            self?.styleSheetUpdateDebouncer?.call()
                        }
                    })
                    pathMonitor?.startFileMonitoring()
                }
            }

            contentViewController?.sendStyleSheetToSelfAndDescendentHolders(styleSheet)

            if let window = window, let computedStyle = styleSheet?.computedStyleForElement("window") {
                window.appearance = computedStyle.allValues[.appearance] as? NSAppearance ?? nil // NSAppearance(named: NSAppearance)
            }
        }
    }

    open var outlineEditor: OutlineEditorType? {
        didSet {
            contentViewController?.sendToOutlineEditorToSelfAndDescendentHolders(outlineEditor)
            sidebarSelectionDisposable?.dispose()
            sidebarSelectionDisposable = outlineEditor?.outlineSidebar?.onDidChangeSelection { [weak self] in
                self?.synchronizeWindowTitleWithDocumentName()
                self?.contentViewController?.view.needsUpdateConstraints = true
            }
        }
    }

    override open var document: AnyObject? {
        didSet {
            if let document = document as? OutlineDocument {
                let newStyleSheet = BirchEditor.createStyleSheet(nil)
                outlineEditor = BirchEditor.createOutlineEditor(document.outline, styleSheet: newStyleSheet)
                styleSheet = newStyleSheet
            } else {
                outlineEditor = nil
            }
        }
    }

    fileprivate var saveFrames = false

    override open func windowDidLoad() {
        super.windowDidLoad()

        if let window = window {
            userDefaults.addObserver(self, forKeyPath: BUserFontSizeDefaultsKey, options: .new, context: nil)

            window.contentView?.wantsLayer = true // round corners, animated titlebar
            hideTitlebar()

            /* showTitlebarDebouncer = Debouncer(delay: 0.15, callback: { [weak self] in
                 self?.showTitlebar()
             })

             hideTitlebarDebouncer = Debouncer(delay: 0.3, callback: { [weak self] in
                 self?.hideTitlebar()
             }) */

            PreviewTitlebarAccessoryViewController.addPreviewTitlebarAccessoryIfNeeded(window)

            shouldCascadeWindows = false
            window.setFrameUsingName(DocumentWindowFrameAutosaveName)
            let frame = window.frame
            let topLeft = NSPoint(x: NSMinX(frame), y: NSMaxX(frame))
            for each in NSApp.windows {
                if each != window {
                    let eachFrame = each.frame
                    let eachTopLeft = NSPoint(x: NSMinX(eachFrame), y: NSMaxX(eachFrame))
                    if NSEqualPoints(topLeft, eachTopLeft) {
                        let newTopLeft = window.cascadeTopLeft(from: topLeft)
                        window.setFrameTopLeftPoint(newTopLeft)
                        break
                    }
                }
            }

            windowEffectiveAppearanceObserver = window.observe(\.effectiveAppearance) { [weak self] _, _ in
                if let `self` = self, let currentStyleSheet = self.styleSheet {
                    self.styleSheet = BirchEditor.createStyleSheet(currentStyleSheet.source)
                }
            }
        }

        saveFrames = true
    }

    var windowEffectiveAppearanceObserver: NSKeyValueObservation?

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == BUserFontSizeDefaultsKey {
            if let currentStyleSheet = styleSheet {
                styleSheet = BirchEditor.createStyleSheet(currentStyleSheet.source)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    override open func synchronizeWindowTitleWithDocumentName() {
        super.synchronizeWindowTitleWithDocumentName()

        if #available(OSX 10.13, *) {
            if let window = (window as? OutlineEditorWindow) {
                let selectedItemTitle = outlineEditor?.outlineSidebar?.selectedItem?.title ?? ""
                if window.isTabbedWindowWithSingleDocument {
                    window.tab.title = selectedItemTitle
                } else {
                    window.tab.title = "\(window.title) • \(selectedItemTitle)"
                }
            }
        }
    }

    override open func windowTitle(forDocumentDisplayName displayName: String) -> String {
        return displayName
    }

    func hideTitlebar() {
        // simulatedTitleBar.hidden = true
        // window?.standardWindowButton(.DocumentVersionsButton)?.layer?.opacity = 0.5
        // window?.standardWindowButton(.DocumentVersionsButton)?.hidden = true
        // window?.titlebarAppearsTransparent = true
        // window?.titleVisibility = .Hidden
    }

    func showTitlebar() {
        // simulatedTitleBar.hidden = false
        // window?.standardWindowButton(.DocumentVersionsButton)?.layer?.opacity = 1
        // window?.titlebarAppearsTransparent = false
        // window?.titleVisibility = .Visible
    }

    @IBAction func newWindow(_ sender: Any?) {
        if let document = document as? OutlineDocument {
            let windowController = document.makeWindowController()
            document.addWindowController(windowController)
            windowController.window?.makeKeyAndOrderFront(sender)
        }
    }

    @IBAction func showCollectionViewEditor(_: Any?) {
        if let outlineEditor = outlineEditor {
            let popover = NSPopover()
            let storyboard = NSStoryboard(name: "OutlineEditorCollectionView", bundle: Bundle(for: OutlineSidebarViewController.self))
            let viewController = storyboard.instantiateController(withIdentifier: "Outline Editor Collection View Controller") as? OutlineEditorCollectionViewController

            viewController?.outlineEditor = outlineEditor

            popover.contentSize = NSMakeSize(400, 800)
            popover.behavior = .applicationDefined
            popover.contentViewController = viewController

            popover.show(relativeTo: contentViewController!.view.bounds, of: contentViewController!.view, preferredEdge: .maxY)
        }
    }

    @available(OSX 10.12, *)
    @IBAction func newTab(_: Any?) {
        if let document = document as? OutlineDocument {
            let windowController = document.makeWindowController()
            document.addWindowController(windowController)
            if let newWindow = windowController.window {
                window?.addTabbedWindow(newWindow, ordered: .above)
                newWindow.makeKeyAndOrderFront(nil)
            }
        }
    }

    deinit {
        pathMonitor?.stopMonitoring()
        pathMonitor = nil
        styleSheetUpdateDebouncer?.cancel()
        styleSheetUpdateDebouncer = nil
        sidebarSelectionDisposable?.dispose()
        windowEffectiveAppearanceObserver?.invalidate()
        userDefaults.removeObserver(self, forKeyPath: BUserFontSizeDefaultsKey)
    }
}

extension OutlineEditorWindowController: NSWindowDelegate {
    public func windowDidBecomeMain(_: Notification) {
        if saveFrames {
            window?.saveFrame(usingName: DocumentWindowFrameAutosaveName)
        }
    }

    public func windowDidResignMain(_: Notification) {}

    public func windowDidResize(_: Notification) {
        if saveFrames {
            window?.saveFrame(usingName: DocumentWindowFrameAutosaveName)
        }
    }

    public func windowDidMove(_: Notification) {
        if saveFrames {
            window?.saveFrame(usingName: DocumentWindowFrameAutosaveName)
        }
    }
}
