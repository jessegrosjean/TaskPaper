
//
//  OutlineEditorTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/3/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import JavaScriptCore
@testable import TaskPaper
import XCTest

class OutlineEditorTests: XCTestCase {
    var outline: OutlineType!
    weak var weakOutline: OutlineType?
    var outlineEditor: OutlineEditorType!
    weak var weakOutlineEditor: OutlineEditorType?

    override func setUp() {
        super.setUp()
        outline = BirchEditor.createTaskPaperOutline(nil)
        weakOutline = outline
        outlineEditor = BirchEditor.createOutlineEditor(outline)
        weakOutlineEditor = outlineEditor

        let path = Bundle(for: BirchScriptContext.self).path(forResource: "OutlineFixture", ofType: "bml")!
        let textContents = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
        outline.reloadSerialization(textContents as String, options: ["type": "text/bml+html"])

        XCTAssertEqual(outline.retainCount, 1)
    }

    override func tearDown() {
        outlineEditor = nil
        XCTAssertNil(weakOutlineEditor)
        XCTAssertEqual(outline.retainCount, 0)
        outline = nil
        XCTAssertNil(weakOutline)
        super.tearDown()
    }

    func testInit() {
        XCTAssertNotNil(outline)
        XCTAssertNotNil(outlineEditor)
    }

    func testEvaluateScript() {
        let results = outlineEditor.evaluateScript("function(editor, options) { return options.a }", withOptions: ["a": "jesse"]) as! String
        XCTAssertEqual(results, "jesse")
    }

    func testInsertText() {
        outlineEditor.replaceRangeWithString(NSMakeRange(0, outlineEditor.textStorage.length), string: "Hello world")
        XCTAssertEqual(outlineEditor.textStorage.string, "Hello world\n")
    }

    func testInsertUndo() {
        let originalText = outlineEditor.textStorage.string
        outlineEditor.replaceRangeWithString(NSMakeRange(0, outlineEditor.textStorage.length), string: "Hello world")
        outlineEditor?.performCommand("outline-editor:undo", options: nil)
        XCTAssertEqual(outlineEditor.textStorage.string, originalText)
    }

    func testPerformCommand() {
        outlineEditor.performCommand("outline-editor:newline", options: nil)
    }
}
