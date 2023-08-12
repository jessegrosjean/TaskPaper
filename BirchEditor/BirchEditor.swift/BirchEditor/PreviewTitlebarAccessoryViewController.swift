//
//  PreviewTitlebarAccessoryViewController.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/19/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

let previewTitlebarAccessoryBundle = Bundle(for: PreviewTitlebarAccessoryViewController.self)
let previewTitlebarAccessoryStoryboard = NSStoryboard(name: "PreviewTitlebarAccessory", bundle: previewTitlebarAccessoryBundle)

class PreviewTitlebarAccessoryViewController: NSTitlebarAccessoryViewController {
    static func addPreviewTitlebarAccessoryIfNeeded(_ window: NSWindow) {
        if !userDefaults.bool(forKey: BShowPreviewBadge) {
            return
        }

        if NSApp.isPreview {
            let previewController = previewTitlebarAccessoryStoryboard.instantiateController(withIdentifier: "Preview Titlebar Accessory View Controller") as! PreviewTitlebarAccessoryViewController
            previewController.layoutAttribute = .right
            window.addTitlebarAccessoryViewController(previewController)
            if #available(OSX 10.12, *) {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    // Hack otherwise not showing up even though reports as proper location in view debugger
                    previewController.isHidden = true
                    previewController.isHidden = false
                }
            }
        }
    }

    @IBOutlet var previewButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.setFrameSize(view.fittingSize) // not sure why this is neccesarry... shouldn't autolayout do this?
    }

    @IBAction func previewButtonClicked(_: Any?) {
        let alert = NSAlert()
        let appName = ProcessInfo.processInfo.processName
        alert.messageText = NSLocalizedString("\(appName) Preview Release", tableName: "PreviewReleaseAlert", comment: "message")
        alert.informativeText = NSLocalizedString("Watch out! I'm still working on this version of \(appName). Thanks for your Feedback!", tableName: "PreviewReleaseAlert", comment: "informative text")
        alert.addButton(withTitle: NSLocalizedString("OK", tableName: "PreviewReleaseAlert", comment: "button"))
        alert.addButton(withTitle: NSLocalizedString("Feedback", tableName: "PreviewReleaseAlert", comment: "button"))
        alert.beginSheetModal(for: view.window!, completionHandler: { modalResponse in
            if modalResponse == NSApplication.ModalResponse.alertSecondButtonReturn {
                NSWorkspace.shared.open(URL(string: "http://support.hogbaysoftware.com/c/\(appName.lowercased())/")!)
            }
        })
    }
}
