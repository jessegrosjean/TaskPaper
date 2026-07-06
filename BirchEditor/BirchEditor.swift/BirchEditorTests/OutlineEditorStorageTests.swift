//
//  OutlineEditorTextStorageTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/6/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import JavaScriptCore
@testable import TaskPaper
import XCTest

@MainActor
class OutlineEditorTextStorageTests: XCTestCase {
    var outline: OutlineType!
    weak var weakOutline: OutlineType?
    var outlineEditor: OutlineEditorType!
    weak var weakOutlineEditor: OutlineEditorType?
    var outlineEditorTextStorage: OutlineEditorTextStorage!
    weak var weakOutlineEditorTextStorage: OutlineEditorTextStorage?

    // setUp()/tearDown() overrides stay nonisolated (inherited from the
    // superclass); XCTest invokes them on the main thread for synchronous
    // tests, so assumeIsolated is safe here.
    override func setUp() {
        super.setUp()
        MainActor.assumeIsolated {
            outline = BirchEditor.createTaskPaperOutline(nil)
            weakOutline = outline
            outlineEditor = BirchEditor.createOutlineEditor(outline, styleSheet: nil)
            weakOutlineEditor = outlineEditor
            outlineEditorTextStorage = outlineEditor.textStorage
            weakOutlineEditorTextStorage = outlineEditorTextStorage
            let path = Bundle(for: BirchScriptContext.self).path(forResource: "OutlineFixture", ofType: "bml")!
            let textContents = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
            outline.reloadSerialization(textContents as String, options: ["type": "text/bml+html" as Any])
            XCTAssertEqual(outline.retainCount, 1)
        }
    }

    override func tearDown() {
        MainActor.assumeIsolated {
            outlineEditor = nil
            XCTAssertNil(weakOutlineEditor)
            outlineEditorTextStorage = nil
            XCTAssertNil(weakOutlineEditorTextStorage)
            XCTAssertEqual(outline.retainCount, 0)
            outline = nil
            XCTAssertNil(weakOutline)
        }
        super.tearDown()
    }

    func testStorageItemLookupByIndex() {
        XCTAssertEqual(outlineEditorTextStorage.itemAtIndex(0)!.body, "one")
        XCTAssertEqual(outlineEditorTextStorage.itemAtIndex(4)!.body, "two")
    }

    func testStorageItemLookupByID() {
        XCTAssertEqual(outlineEditorTextStorage.itemForID("1").body, "one")
        XCTAssertEqual(outlineEditorTextStorage.itemForID("2").body, "two")
    }

    func testOutlineChangesReflectedInTextStorage() {
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        item.body = "moose"
        XCTAssertEqual(outlineEditorTextStorage.string, "moose\ntwo\nthree @t\nfour @t\nfive\nsix @t(23)\n")
    }

    func testTextStorageChangesReflextedInOutline() {
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "moose")
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        XCTAssertEqual(item.body, "mooseone")
    }

    func testTextStorageChangesWeirdoCharactersReflextedInOutline() {
        outlineEditorTextStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: "Άά Έέ Ήή Ίί Όό Ύύ Ώώ")
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        XCTAssertEqual(item.body, "Άά Έέ Ήή Ίί Όό Ύύ Ώώone")
    }

    func testInsertIntoEmptyAddsTrailingNewline() {
        outline = BirchEditor.createTaskPaperOutline(nil)
        outlineEditor = BirchEditor.createOutlineEditor(outline)
        outlineEditorTextStorage = outlineEditor.textStorage
        outlineEditorTextStorage.replaceCharacters(in: NSMakeRange(0, 0), with: "Hello")
        XCTAssertEqual(outlineEditorTextStorage.string, "Hello\n")
    }

    // MARK: - Crash reproduction: fillBackingStoreAttributesInRange index out of range

    // Reproduces the crash at OutlineEditorTextStorage.swift:115 where
    // paragraphRanges.count != storeItems.count. This happens when JS
    // modifies items and calls endEditing() on the WeakProxy, which
    // triggers NSLayoutManager to request attributes via
    // fillBackingStoreAttributesInRange before the models are in sync.

    func testDeleteAllItemsViaScriptDoesNotCrash() {
        // Crash path 1: AppleScript evaluateScript that removes all items.
        // The JS side deletes items then endEditing() triggers layout
        // invalidation while paragraph ranges still reflect the old content.
        _ = outlineEditorTextStorage.itemAtIndex(0) // force initial styling
        outlineEditor.evaluateScript(
            "function(editor) { var items = editor.outline.root.children; editor.outline.root.removeChildren(items); }",
            withOptions: nil
        )
    }

    func testDeleteItemsThenUndoDoesNotCrash() {
        // Crash path 2: Undo after deleting items. The undo re-inserts
        // items via JS which calls endEditing(), triggering attribute
        // fixup while paragraph/item counts are mismatched.
        _ = outlineEditorTextStorage.itemAtIndex(0)
        outlineEditor.evaluateScript(
            "function(editor) { var items = editor.outline.root.children; editor.outline.root.removeChildren(items); }",
            withOptions: nil
        )
        outlineEditor.performCommand("outline-editor:undo", options: nil)
    }

    func testReplaceAllTextThenUndoDoesNotCrash() {
        // Another undo variant: replace all text (merging/splitting items)
        // then undo to restore the original item structure.
        _ = outlineEditorTextStorage.itemAtIndex(0)
        let fullLength = outlineEditorTextStorage.length
        outlineEditorTextStorage.replaceCharacters(in: NSMakeRange(0, fullLength), with: "single item")
        outlineEditor.performCommand("outline-editor:undo", options: nil)
    }

    func testMouseOverItemChangeAfterItemDeleteDoesNotCrash() {
        // Crash path 3: Setting mouseOverItem triggers JS
        // beginEditing/invalidateItem/endEditing cycle. If the item
        // was just deleted, the invalidation range is stale.
        let item = outlineEditorTextStorage.itemAtIndex(0)!
        outlineEditor.mouseOverItem = item
        item.removeFromParent()
        outlineEditor.mouseOverItem = nil
    }

    func testRapidInsertDeleteCycleDoesNotCrash() {
        // Stress test: rapidly add and remove items to trigger the
        // paragraph/item count mismatch during endEditing callbacks.
        _ = outlineEditorTextStorage.itemAtIndex(0)
        for i in 0..<20 {
            outlineEditor.evaluateScript(
                "function(editor) { var item = editor.outline.createItem('stress \(i)'); editor.outline.root.appendChild(item); }",
                withOptions: nil
            )
        }
        // Delete them all at once — large structural change
        outlineEditor.evaluateScript(
            "function(editor) { var items = editor.outline.root.children; editor.outline.root.removeChildren(items); }",
            withOptions: nil
        )
        // Undo the mass delete
        outlineEditor.performCommand("outline-editor:undo", options: nil)
    }

    // MARK: - Performance

    func testPerformance() {
        var bigText = ""
        for _ in 1 ... 1000 {
            bigText += "- hello\n"
        }

        measure {
            self.outline.reloadSerialization(bigText, options: ["type": "text/plain"])
            _ = self.outlineEditorTextStorage.itemAtIndex(0) // force styling storage
        }
    }
}
