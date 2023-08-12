//
//  OutlineDocumentTests.swift
//  Birch
//
//  Created by Jesse Grosjean on 8/22/16.
//
//

import BirchOutline
import JavaScriptCore
@testable import TaskPaper
import XCTest

class OutlineDocument: XCTestCase {
    var document: TaskPaperDocument?
    weak var weakDocument: TaskPaperDocument?

    override func setUp() {
        super.setUp()
        autoreleasepool {
            document = try! NSDocumentController.shared().makeUntitledDocument(ofType: "com.taskpaper.text") as? TaskPaperDocument
        }
        weakDocument = document
    }

    override func tearDown() {
        autoreleasepool {
            document?.close()
            document = nil
        }

        let expectation = self.expectation(description: "Should Deinit")
        delay(0) {
            while self.weakDocument != nil {
                RunLoop.current.run(until: NSDate(timeIntervalSinceNow: 0.1) as Date)
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("Error: \(error.localizedDescription)")
            }
        }

        XCTAssertNil(weakDocument)

        super.tearDown()
    }

    func testCreateDocument() {
        XCTAssertNotNil(document)
        XCTAssertNil(document?.undoManager)
        XCTAssertFalse(document!.hasUnautosavedChanges)
        XCTAssertFalse(document!.isDocumentEdited)
    }

    func testInsertText() {
        let item = document?.outline.createItem("Hello world")
        document?.outline.root.appendChildren([item!])
        XCTAssertTrue(document!.hasUnautosavedChanges)
        XCTAssertTrue(document!.isDocumentEdited)
    }

    func testSave() {
        autoreleasepool {
            let item = document?.outline.createItem("Hello world")
            let expectation = self.expectation(description: "Should Save")
            document?.outline.root.appendChildren([item!])
            let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/test.taskpaper")

            document?.save(to: url, ofType: "com.taskpaper.text", for: .saveOperation, completionHandler: { _ in
                XCTAssertFalse(self.document!.isDocumentEdited)
                XCTAssertFalse(self.document!.hasUnautosavedChanges)
                expectation.fulfill()
            })

            waitForExpectations(timeout: 1.0) { error in
                if let error = error {
                    XCTFail("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}
