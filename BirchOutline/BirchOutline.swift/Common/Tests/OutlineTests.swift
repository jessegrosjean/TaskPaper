//
//  OutlineTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import XCTest
import JavaScriptCore
@testable import BirchOutline

class OutlineTests: XCTestCase {

    var outline: OutlineType!
    weak var weakOutline: OutlineType?
    
    override func setUp() {
        super.setUp()
        let path = Bundle(for: BirchScriptContext.self).path(forResource: "OutlineFixture", ofType: "txt")!
        let textContents = try! NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
        outline = BirchOutline.createTaskPaperOutline(textContents as String)
        weakOutline = outline
    }
    
    override func tearDown() {
        outline = nil
        XCTAssertNil(weakOutline)
    }

    func testInit() {
        XCTAssertNotNil(outline)
        XCTAssertEqual(outline.root.firstChild!.firstChild!.body, "two")
    }

    func testRemoveFromParent() {
        let two = outline.root.firstChild!.firstChild!
        two.removeFromParent()
        XCTAssertEqual(outline.root.firstChild!.firstChild!.body, "five")
        XCTAssertNil(two.parent)
        XCTAssertEqual(outline.serialize(nil), "one\n\tfive\n\t\tsix")
    }

    func testSetTextContent() {
        outline.reloadSerialization("one\n\ttwo @done\n\tthree", options: nil)
        XCTAssertEqual(outline.root.firstChild!.body, "one")
        XCTAssertEqual(outline.root.lastChild!.body, "one")
        XCTAssertEqual(outline.serialize(nil), "one\n\ttwo @done\n\tthree")
    }

    func testItems() {
        XCTAssertEqual(outline.items[0].body, "one")
        XCTAssertEqual(outline.items[5].body, "six")
    }

    func testCloneItems() {
        let oneCloned = outline.cloneItems([outline.root.firstChild!], deep: true)[0]
        XCTAssertEqual(oneCloned.body, "one")
        XCTAssertEqual(oneCloned.firstChild!.body, "two")
    }

    func testEvaluateItemPath() {
        XCTAssertEqual(outline.evaluateItemPath("one")[0].body, "one")
    }

    func testOnDidUpdateChangeCountDone() {
        let disposable = outline.onDidUpdateChangeCount { changeType in
            XCTAssertEqual(changeType, .done)
        }
        outline.root.firstChild!.body = "moose"
        disposable.dispose()
    }
    
    func testOnDidUpdateChangeCountUndone() {
        outline.root.firstChild!.body = "moose"
        let disposable = outline.onDidUpdateChangeCount { changeType in
            XCTAssertEqual(changeType, .undone)
        }
        outline.undo()
        disposable.dispose()
        
    }

}
