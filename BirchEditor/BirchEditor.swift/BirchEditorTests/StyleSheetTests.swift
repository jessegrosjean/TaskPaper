//
//  StyleSheetTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/9/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import JavaScriptCore
@testable import TaskPaper
import XCTest

class StyleSheetTests: XCTestCase {
    var styleSheet: StyleSheet?
    weak var weakStyleSheet: StyleSheet?

    override func setUp() {
        styleSheet = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        weakStyleSheet = styleSheet
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        styleSheet = nil
        XCTAssertNil(weakStyleSheet)
    }

    func testComputeStyleKeyForElement() {
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNil(computedStyle?.allValues["missingkey"])
        XCTAssertNotNil(computedStyle?.allValues["appearance"])
    }
}
