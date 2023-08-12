//
//  OutlineEditorWindowTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 8/23/16.
//
//

import BirchOutline
import JavaScriptCore
@testable import TaskPaper
import XCTest

class OutlineEditorWindowControllerTests: XCTestCase {
    var document: TaskPaperDocument?
    weak var weakDocument: TaskPaperDocument?

    var windowController: TaskPaperWindowController?
    weak var weakWindowController: TaskPaperWindowController?

    var window: NSWindow?
    weak var weakWindow: NSWindow?

    var outlineEditor: OutlineEditorType?
    weak var weakOutlineEditor: OutlineEditorType?

    var textStorage: OutlineEditorTextStorage?
    weak var weakTextStorage: OutlineEditorTextStorage?

    var splitViewController: TaskPaperOutlineEditorSplitViewController?
    weak var weakSplitViewController: TaskPaperOutlineEditorSplitViewController?
    var splitView: NSView?
    weak var weakSplitView: NSView?

    var sidebar: OutlineSidebarType?
    weak var weakSidebar: OutlineSidebarType?

    var sidebarViewController: OutlineSidebarViewController?
    weak var weakOutlineSidebarViewController: OutlineSidebarViewController?

    var sidebarView: OutlineSidebarView?
    weak var weakOutlineSidebarView: OutlineSidebarView?

    var outlineEditorViewController: OutlineEditorViewController?
    weak var weakOutlineEditorViewController: OutlineEditorViewController?

    var outlineEditorView: OutlineEditorView?
    weak var weakOutlineEditorView: OutlineEditorView?

    override func setUp() {
        super.setUp()
        autoreleasepool {
            document = try! NSDocumentController.shared().makeUntitledDocument(ofType: "com.taskpaper.text") as? TaskPaperDocument
            weakDocument = document

            document?.makeWindowControllers()
            windowController = document?.windowControllers[0] as? TaskPaperWindowController
            weakWindowController = windowController

            window = windowController?.window
            weakWindow = window
            window?.makeKeyAndOrderFront(nil)

            outlineEditor = windowController?.outlineEditor
            weakOutlineEditor = outlineEditor

            sidebar = outlineEditor?.outlineSidebar
            weakSidebar = sidebar

            textStorage = outlineEditor?.textStorage
            weakTextStorage = textStorage

            splitViewController = windowController?.contentViewController as? TaskPaperOutlineEditorSplitViewController
            weakSplitViewController = splitViewController
            splitView = splitViewController?.splitView
            weakSplitView = splitView

            sidebarViewController = splitViewController?.sidebarViewController
            weakOutlineSidebarViewController = sidebarViewController

            sidebarView = sidebarViewController?.sidebarView
            weakOutlineSidebarView = sidebarView

            outlineEditorViewController = splitViewController?.outlineEditorViewController
            weakOutlineEditorViewController = outlineEditorViewController
        }
        // outlineEditorView = outlineEditorViewController?.outlineEditorView
        // weakOutlineEditorView = outlineEditorView
    }

    override func tearDown() {
        autoreleasepool {
            document?.close()
            document = nil
            windowController = nil
            window = nil
            outlineEditor = nil
            textStorage = nil
            splitViewController = nil
            splitView = nil
            sidebar = nil
            sidebarViewController = nil
            sidebarView = nil
            outlineEditorViewController = nil
            outlineEditorView = nil
        }

        document = nil

        func allDeinited() -> Bool {
            return weakDocument == nil &&
                weakWindowController == nil &&
                weakWindow == nil &&
                weakOutlineEditor == nil &&
                weakTextStorage == nil &&
                weakSplitViewController == nil &&
                weakSidebar == nil &&
                weakOutlineSidebarViewController == nil &&
                weakOutlineSidebarView == nil &&
                weakOutlineEditorViewController == nil &&
                weakOutlineEditorView == nil
        }

        let expectation = self.expectation(description: "Should Deinit")
        delay(0) {
            while !allDeinited() {
                RunLoop.current.run(until: NSDate(timeIntervalSinceNow: 0.1) as Date)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("Error: \(error.localizedDescription)")
            }
        }

        XCTAssert(allDeinited())

        super.tearDown()
    }

    func testCreateDocument() {
        XCTAssertNotNil(document)
        XCTAssertNotNil(windowController)
        XCTAssertNotNil(window)
        XCTAssertNotNil(outlineEditor)
        XCTAssertNotNil(sidebar)
        XCTAssertNotNil(textStorage)
        XCTAssertNotNil(splitViewController)
        XCTAssertNotNil(sidebarViewController)
        XCTAssertNotNil(sidebarView)
        XCTAssertNotNil(outlineEditorViewController)
        // XCTAssertNotNil(outlineEditorView)
    }
}
