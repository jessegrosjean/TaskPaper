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

class OutlineEditorTextStorageTests: XCTestCase {
    var outline: OutlineType!
    weak var weakOutline: OutlineType?
    var outlineEditor: OutlineEditorType!
    weak var weakOutlineEditor: OutlineEditorType?
    var outlineEditorTextStorage: OutlineEditorTextStorage!
    weak var weakOutlineEditorTextStorage: OutlineEditorTextStorage?

    override func setUp() {
        super.setUp()
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

    override func tearDown() {
        outlineEditor = nil
        XCTAssertNil(weakOutlineEditor)
        outlineEditorTextStorage = nil
        XCTAssertNil(weakOutlineEditorTextStorage)
        XCTAssertEqual(outline.retainCount, 0)
        outline = nil
        XCTAssertNil(weakOutline)
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
