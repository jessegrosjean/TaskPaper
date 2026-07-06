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

@MainActor
class OutlineDocument: XCTestCase {
    var document: TaskPaperDocument?
    weak var weakDocument: TaskPaperDocument?

    // The async overrides may add @MainActor isolation (callers await),
    // which puts setup/teardown on the main actor alongside the tests.
    @MainActor
    override func setUp() async throws {
        autoreleasepool {
            document = try! NSDocumentController.shared.makeUntitledDocument(ofType: "com.taskpaper.text") as? TaskPaperDocument
        }
        weakDocument = document
    }

    @MainActor
    override func tearDown() async throws {
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

        await fulfillment(of: [expectation], timeout: 5)

        XCTAssertNil(weakDocument)
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
