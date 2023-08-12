//
//  ItemTypeTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import XCTest
import JavaScriptCore
@testable import BirchOutline

class ItemTests: XCTestCase {
    
    var outline: OutlineType!
    weak var weakOutline: OutlineType?
    var item: ItemType!
    
    override func setUp() {
        super.setUp()
        
        outline = BirchOutline.createTaskPaperOutline(nil)
        weakOutline = outline
        item = outline.createItem("hello")
    }
    
    override func tearDown() {
        item = nil
        outline = nil
        XCTAssertNil(weakOutline)
    }
    
    func testInit() {
        XCTAssertNotNil(item)
        XCTAssertEqual(item.body, "hello")
        XCTAssertEqual(item.attributes, ["data-type":"note"])
        XCTAssertNil(item.attributeForName("notfound"))
    }

    func testSetAttribute() {
        item.setAttribute("one", value: "two")
        XCTAssertEqual(item.attributes, ["one":"two", "data-type":"note"])
        XCTAssertEqual(item.attributeForName("one"), "two")
    }

    func testSetBody() {
        item.body = "hello again"
        XCTAssertEqual(item.body, "hello again")
    }

    func testInsertChildren() {
        item.insertChildren([outline.createItem("child 1"), outline.createItem("child 2")], beforeSibling: nil)
        XCTAssertEqual(item.firstChild!.body, "child 1")
        XCTAssertEqual(item.firstChild!.nextSibling!.body, "child 2")
    }

    func testAppendChildren() {
        let two = outline.createItem("two")
        let three = outline.createItem("three")
        two.setAttribute("data-priority", value: "1")
        three.setAttribute("data-type", value: "task")
        item.appendChildren([two, three])
        outline.root.appendChildren([item])
        XCTAssertEqual(outline.serialize(nil), "hello\n\ttwo @priority(1)\n\t- three")
    }

    func testRemoveChildren() {
        let children = [outline.createItem("child 1"), outline.createItem("child 2")]
        item.insertChildren(children, beforeSibling: nil)
        item.removeChildren(children)
        XCTAssertNil(item.firstChild)
    }

}
