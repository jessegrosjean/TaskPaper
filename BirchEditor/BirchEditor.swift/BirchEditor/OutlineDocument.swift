//
//  Document.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/26/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

open class OutlineDocument: NSDocument {
    open var outline: OutlineType!
    var presentedItemDidChangeDebouncer: Debouncer?
    var editorDefaultRestorableState: String?
    var isUpdatingChangeCountFromOutline = false
    var isUpdatingChangeCountFromDocument = false
    var windowForSheetHack: NSWindow?
    var isReverting = false

    public convenience init(type typeName: String) throws {
        self.init()
        fileType = typeName
        if userDefaults.bool(forKey: BShowWelcomeText) {
            if let url = Bundle.main.url(forResource: "Welcome", withExtension: "txt") {
                let string = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
                if let data = string.data(using: String.Encoding.utf8.rawValue) {
                    try read(from: data, ofType: typeName)
                }
            }
        }
    }

    fileprivate var disposable: DisposableType?

    var outlineRuntimeType: String {
        return "notype"
    }

    override public init() {
        super.init()
        undoManager = nil
        outline = BirchOutline.sharedContext.createOutline(outlineRuntimeType, content: nil)
        presentedItemDidChangeDebouncer = Debouncer(delay: 0.5, callback: { [weak self] in
            self?.manualRefreshDocumentFromDisk()
        })
        disposable = outline.onDidUpdateChangeCount { [weak self] changeKind in
            if let strongSelf = self {
                if !strongSelf.isUpdatingChangeCountFromDocument {
                    strongSelf.isUpdatingChangeCountFromOutline = true
                    strongSelf.updateChangeCount(changeKind.toCocoaChangeKind())
                    strongSelf.isUpdatingChangeCountFromOutline = false
                }
            }
        }
    }

    deinit {
        disposable?.dispose()
        presentedItemDidChangeDebouncer?.cancel()
    }

    // MARK: - Data

    override open class var autosavesInPlace: Bool {
        return true
    }

    override open class func canConcurrentlyReadDocuments(ofType _: String) -> Bool {
        return false
    }

    override open func updateChangeCount(withToken changeCountToken: Any, for saveOperation: NSDocument.SaveOperationType) {
        super.updateChangeCount(withToken: changeCountToken, for: saveOperation)

        // Must bread undo coalescing after save so that future edits aren't just coalested into the previous mutation. If that happens then
        // change count never updates (unless do some other edit that breaks undo coalescing) and those last coalested changes wont be
        // autosaved if user quits app without explictly saving.

        outline.breakUndoCoalescing()
    }

    override open func updateChangeCount(_ changeType: NSDocument.ChangeType) {
        super.updateChangeCount(changeType)

        if !isUpdatingChangeCountFromOutline {
            if let changeKind = ChangeKind(changeKind: changeType) {
                isUpdatingChangeCountFromDocument = true
                outline.updateChangeCount(changeKind)
                isUpdatingChangeCountFromDocument = false
            }
        }
    }

    override open func canAsynchronouslyWrite(to _: URL, ofType _: String, for _: NSDocument.SaveOperationType) -> Bool {
        return false
    }

    override open func write(to url: URL, ofType typeName: String) throws {
        try super.write(to: url, ofType: typeName)
        _ = url.setExtendedAttribute(string: outline.serializedMetadata, forName: "com.taskpaper.outline.metadata")
        if let outlineEditor = outlineEditorForSheet {
            _ = url.setExtendedAttribute(string: outlineEditor.serializedRestorableState, forName: "com.taskpaper.editor.defaultRestorableState.\(NSUserName())")
        }
    }

    override open func data(ofType typeName: String) throws -> Data {
        let options: [String: Any] = ["type": typeName]
        // Eventaully need to be smarter hear... handle case where we want to embed metadata inside
        // document format... so must past in as options?
        // if let serializedRestorableState = activeOutlineEditor?.serializedRestorableState {
        //    for key in restorableState.keys {
        //        options[key] = restorableState[key]
        //    }
        // }
        return outline.serialize(options).data(using: String.Encoding.utf8)!
    }

    override open func revert(toContentsOf url: URL, ofType typeName: String) throws {
        isReverting = true
        try super.revert(toContentsOf: url, ofType: typeName)
        isReverting = false
    }

    override open func read(from url: URL, ofType typeName: String) throws {
        try super.read(from: url, ofType: typeName)

        if !isReverting {
            if let serializedMetadata = url.extendedAttributeString(forName: "com.taskpaper.outline.metadata") {
                outline.serializedMetadata = serializedMetadata
                updateChangeCount(.changeCleared)
            }

            if let serializedRestorableState = url.extendedAttributeString(forName: "com.taskpaper.editor.defaultRestorableState.\(NSUserName())") {
                editorDefaultRestorableState = serializedRestorableState
                outlineEditorForSheet?.serializedRestorableState = serializedRestorableState
            }
        }
    }

    override open func read(from data: Data, ofType typeName: String) throws {
        guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            throw BirchError.runtimeError("Failed to decode string as utf8")
        }
        outline.reloadSerialization(string as String, options: ["type": typeName as Any])
    }

    // MARK: - File Refresh

    override open func presentedItemDidChange() {
        super.presentedItemDidChange()
        OperationQueue.main.addOperation { [weak self] in
            self?.presentedItemDidChangeDebouncer?.call()
        }
    }

    @objc func manualRefreshDocumentFromDisk() {
        guard !hasUnautosavedChanges else {
            return
        }

        performAsynchronousFileAccess { [weak self] completionHandler in
            guard let `self` = self, let fileURL = self.fileURL, !self.hasUnautosavedChanges else {
                completionHandler()
                return
            }

            let fileCoordinator = NSFileCoordinator(filePresenter: self)
            var coordinatorError: NSError?
            fileCoordinator.coordinate(readingItemAt: fileURL, options: .withoutChanges, error: &coordinatorError) { newURL in
                guard let fileModificationDate = self.fileModificationDate, !self.hasUnautosavedChanges else {
                    return
                }

                var newFileModificationDate: AnyObject?
                _ = try? (newURL as NSURL).getResourceValue(&newFileModificationDate, forKey: URLResourceKey.contentModificationDateKey)
                if let newFileModificationDate = newFileModificationDate as? Date, newFileModificationDate != fileModificationDate {
                    if newFileModificationDate.timeIntervalSince(fileModificationDate) >= 0.5 {
                        _ = try? self.revert(toContentsOf: newURL, ofType: self.fileType ?? "")
                    } else {
                        self.perform(#selector(self.manualRefreshDocumentFromDisk), with: nil, afterDelay: 0.5)
                    }
                }
            }

            completionHandler()

            if let error = coordinatorError {
                self.presentError(error)
            }
        }
    }

    // MARK: - Window Controllers

    override open var windowForSheet: NSWindow? {
        // In a roundabout way windowForSheet is responsible for determining if new windows should show autosave button
        // which is the button used to indicate "Edited" status. Default machinery seems to always favor first document for that
        // other documents are expected to be panels I guess. This hack is used to make sure window freshkty added to document reports
        // true to windowForSheet so that it gets that autosave button adn shows edited status.
        if let window = windowForSheetHack {
            return window
        }

        var mainWindow: NSWindow?
        var canBeMainWindows = [NSWindow]()

        for each in windowControllers {
            if let _ = each as? OutlineEditorHolderType {
                if let eachWindow = each.window {
                    if eachWindow.isKeyWindow, eachWindow.isMainWindow {
                        return eachWindow
                    } else if eachWindow.isMainWindow {
                        mainWindow = eachWindow
                    } else if eachWindow.canBecomeMain {
                        canBeMainWindows.append(eachWindow)
                    }
                }
            }
        }

        if mainWindow != nil {
            return mainWindow
        }

        return canBeMainWindows.sorted { $0.orderedIndex < $1.orderedIndex }.first ?? super.windowForSheet
    }

    var outlineEditorForSheet: OutlineEditorType? {
        return (windowForSheet?.windowController as? OutlineEditorWindowController)?.outlineEditor
    }

    @IBAction open func newWindowController(_ sender: Any?) {
        let windowController = makeWindowController()

        addWindowController(windowController)

        if let outlineEditor = windowController.outlineEditor, let id = (sender as? NSMenuItem)?.representedObject as? String {
            if let item = outlineEditor.outline.itemForID(id) {
                outlineEditor.focusedItem = item
            }
        }

        windowController.window?.makeKeyAndOrderFront(sender)
    }

    override open func makeWindowControllers() {
        addWindowController(makeWindowController())
    }

    open func makeWindowController() -> OutlineEditorWindowController {
        let windowController = instantiateWindowController()
        windowController.outlineEditorSerializedRestorableState = outlineEditorForSheet?.serializedRestorableState ?? editorDefaultRestorableState
        return windowController
    }

    open func instantiateWindowController() -> OutlineEditorWindowController {
        assertionFailure("Subclass responsibility")
        return OutlineEditorWindowController()
    }

    override open func addWindowController(_ windowController: NSWindowController) {
        if let outlineEditorWindowController = windowController as? OutlineEditorWindowController {
            // Round about Hack so that all windows assocaited with document will show "Edited" status, not just the first.
            windowForSheetHack = outlineEditorWindowController.window
        }
        super.addWindowController(windowController)
        windowForSheetHack = nil
    }

    override open func close() {
        super.close()
        BirchOutline.sharedContext.garbageCollect()
    }

    override open func restoreWindow(withIdentifier identifier: NSUserInterfaceItemIdentifier, state: NSCoder, completionHandler: @escaping (NSWindow?, Error?) -> Void) {
        if identifier == NSUserInterfaceItemIdentifier(rawValue: "OutlineEditorWindow") {
            // Must do this manually because we can have mutliple windows with same identifier and appkit doesn't handle that case
            let outlineEditorWindowController = makeWindowController()
            addWindowController(outlineEditorWindowController)
            completionHandler(outlineEditorWindowController.window, nil)
        } else {
            super.restoreWindow(withIdentifier: identifier, state: state, completionHandler: completionHandler)
        }
    }

    // MARK: - Printing

    fileprivate var setUpPrintInfoDefaults = false

    override open var printInfo: NSPrintInfo {
        get {
            let printInfo = super.printInfo
            if !setUpPrintInfoDefaults {
                setUpPrintInfoDefaults = true
            }
            return printInfo
        }
        set(printInfo) {
            super.printInfo = printInfo
        }
    }

    override open func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any]) throws -> NSPrintOperation {
        // Local variable inserted by Swift 4.2 migrator.
        let printSettings = convertFromNSPrintInfoAttributeKeyDictionary(printSettings)

        let accessoryController = PrintAccessoryViewController(nibName: "PrintAccessoryViewController", bundle: Bundle(for: OutlineDocument.self))

        let printInfoCopy = printInfo.copy() as! NSPrintInfo
        printInfoCopy.dictionary().addEntries(from: printSettings)

        let imagableBounds = printInfoCopy.imageablePageBounds
        let paperSize = printInfoCopy.paperSize

        printInfoCopy.leftMargin = imagableBounds.minX
        printInfoCopy.rightMargin = paperSize.width - imagableBounds.maxX
        printInfoCopy.topMargin = paperSize.height - imagableBounds.maxY
        printInfoCopy.bottomMargin = imagableBounds.minY
        printInfoCopy.isVerticallyCentered = false
        printInfoCopy.isHorizontallyCentered = false
        printInfoCopy.horizontalPagination = .automatic
        printInfoCopy.verticalPagination = .automatic

        let styleSheet = StyleSheet(source: accessoryController.printStyleSheetURL, scriptContext: BirchOutline.sharedContext)
        let outlineEditor = OutlineEditor(outline: outline, styleSheet: styleSheet, scriptContext: BirchOutline.sharedContext)

        if let restorableState = outlineEditorForSheet?.restorableState {
            outlineEditor.restorableState = restorableState
        }

        let outlineEditorViewController = NSStoryboard(name: "OutlineEditorView", bundle: nil).instantiateController(withIdentifier: "Outline Editor View Controller") as! OutlineEditorViewController
        outlineEditorViewController.outlineEditor = outlineEditor
        outlineEditorViewController.styleSheet = styleSheet
        printInfoCopy.dictionary().setObject(outlineEditorViewController, forKey: "retainTheTextViewControllerUntilPrintOperationFinishes" as NSCopying)

        let outlineEditorView = outlineEditorViewController.outlineEditorView!
        outlineEditorView.setFrameSize(imagableBounds.size)

        let printOperation = NSPrintOperation(view: outlineEditorViewController.outlineEditorView, printInfo: printInfoCopy)
        let printPanel = printOperation.printPanel

        printPanel.addAccessoryController(accessoryController)
        printOperation.jobTitle = displayName
        printOperation.canSpawnSeparateThread = false
        return printOperation
    }

    // MARK: - Scripting

    @objc var textContents: String {
        get {
            return try! NSString(data: data(ofType: fileType ?? ""), encoding: String.Encoding.utf8.rawValue)! as String
        }
        set(text) {
            outline.reloadSerialization(text, options: ["type": fileType ?? ""])
        }
    }

    @objc func handleEvaluateScriptCommand(_ command: NSScriptCommand) -> NSAppleEventDescriptor? {
        let evaluatedArguments = command.evaluatedArguments
        if let script = evaluatedArguments?["Script"] as? String {
            let options = evaluatedArguments?["WithOptions"] as? NSAppleEventDescriptor
            let unpackedOptions = options?.unpack()
            if let result = outlineEditorForSheet?.evaluateScript(script, withOptions: unpackedOptions) {
                return NSAppleEventDescriptor.pack(result)
            }
        }
        return nil
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSPrintInfoAttributeKeyDictionary(_ input: [NSPrintInfo.AttributeKey: Any]) -> [String: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) })
}
