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

    // setUp()/tearDown() overrides stay nonisolated (inherited from the
    // superclass); XCTest invokes them on the main thread for synchronous
    // tests, so assumeIsolated is safe here.
    override func setUp() {
        MainActor.assumeIsolated {
            styleSheet = StyleSheet(source: nil, scriptContext: BirchOutline.sharedContext)
            weakStyleSheet = styleSheet
        }
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        MainActor.assumeIsolated {
            styleSheet = nil
            XCTAssertNil(weakStyleSheet)
        }
    }

    func testComputeStyleKeyForElement() {
        let computedStyle = styleSheet?.computedStyleForElement(["tagName": "window"])
        XCTAssertNotNil(computedStyle)
        XCTAssertNil(computedStyle?.allValues[NSAttributedString.Key("missingkey")])
    }
}
