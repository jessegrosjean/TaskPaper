//
//  Birch_iOSTests.swift
//  Birch iOSTests
//
//  Created by Jesse Grosjean on 6/10/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import XCTest
@testable import BirchOutline

class JavaScriptContextTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInit() {
        XCTAssertNotNil(BirchOutline.sharedContext.context)
        XCTAssertNotNil(BirchOutline.sharedContext.jsBirchExports)
        XCTAssertNotNil(BirchOutline.sharedContext.jsOutlineClass)
    }

}
