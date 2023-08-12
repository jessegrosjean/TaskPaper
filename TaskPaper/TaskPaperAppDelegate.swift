//
//  TaskPaperAppDelegate.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 6/10/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

#if DIRECT
    import Paddle
    import Sparkle
#endif

@NSApplicationMain
class TaskPaperAppDelegate: OutlineEditorAppDelegate {
    override func applicationWillFinishLaunching(_ notification: Notification) {
        super.applicationWillFinishLaunching(notification)
        BirchOutline.sharedContext.jsTaskPaperPluginInitFunction.call(withArguments: [])
    }

    override func applicationDidFinishLaunching(_ aNotification: Notification) {
        _ = NSLocalizedString("Inbox", tableName: "OutlineText", comment: "project name")
        _ = NSLocalizedString("Archive", tableName: "OutlineText", comment: "project name")

        _ = NSLocalizedString("start", tableName: "OutlineText", comment: "tag name")
        _ = NSLocalizedString("today", tableName: "OutlineText", comment: "tag name")
        _ = NSLocalizedString("done", tableName: "OutlineText", comment: "tag name")
        _ = NSLocalizedString("due", tableName: "OutlineText", comment: "tag name")
        _ = NSLocalizedString("priority", tableName: "OutlineText", comment: "tag name")

        #if APPSTORE
        AppReview.requestIf(launches: 7, days: 7)
        #endif

        #if SETAPP
            SCShowReleaseNotesWindowIfNeeded()
        #endif

        #if DIRECT
            let appFeedName = NSApp.isPreview ? "TaskPaper-Preview" : "TaskPaper"
            sparkleFeedURL = URL(string: "https://www.taskpaper.com/assets/app/\(appFeedName).rss")

            let productID = "501879"
            let defaultProductConfig = PADProductConfiguration()
            defaultProductConfig.productName = "TaskPaper"
            defaultProductConfig.vendorName = "Hog Bay Software"
            paddle = Paddle.sharedInstance(withVendorID: "366", apiKey: "a414f98bbd019d419bd6ad0272009340", productID: productID, configuration: defaultProductConfig, delegate: self)
            paddleProduct = PADProduct(productID: productID, productType: PADProductType.sdkProduct, configuration: defaultProductConfig)
        #endif

        super.applicationDidFinishLaunching(aNotification)
    }

    @IBAction func openUsersGuide(_: Any?) {
        NSWorkspace.shared.open(URL(string: "http://www.taskpaper.com/guide")!)
    }

    @IBAction func openFAQs(_: Any?) {
        NSWorkspace.shared.open(URL(string: "http://support.hogbaysoftware.com/t/taskpaper-frequently-asked-questions/949")!)
    }

    @IBAction func openScreencastTutorials(_: Any?) {
        NSWorkspace.shared.open(URL(string: "https://medium.com/hog-bay-software/tagged/tutorial")!)
    }

    @IBAction func openReleaseNotes(_: Any?) {
        NSWorkspace.shared.open(URL(string: "http://www.taskpaper.com/releases")!)
    }

    @IBAction func openSupportForums(_: Any?) {
        NSWorkspace.shared.open(URL(string: "http://support.hogbaysoftware.com/c/taskpaper")!)
    }
}
