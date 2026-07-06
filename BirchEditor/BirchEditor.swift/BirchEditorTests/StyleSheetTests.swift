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

@MainActor
class StyleSheetTests: XCTestCase {
    var styleSheet: StyleSheet?
    weak var weakStyleSheet: StyleSheet?

    // The async overrides may add @MainActor isolation (callers await),
    // which puts setup/teardown on the main actor alongside the tests.
    @MainActor
    override func setUp() async throws {
        styleSheet = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
        weakStyleSheet = styleSheet
    }

    @MainActor
    override func tearDown() async throws {
        styleSheet = nil
        XCTAssertNil(weakStyleSheet)
    }

    func testComputeStyleKeyForElement() {
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNotNil(computedStyle)
        XCTAssertNil(computedStyle?.allValues[NSAttributedString.Key("missingkey")])
    }
}
