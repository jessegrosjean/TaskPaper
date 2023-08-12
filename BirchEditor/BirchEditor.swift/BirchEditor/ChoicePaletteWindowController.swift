//
//  ChoicePaletteWindowController.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

let choicePaletteBundle = Bundle(for: ChoicePaletteWindowController.self)
let choicePaletteStoryboard = NSStoryboard(name: "ChoicePalette", bundle: choicePaletteBundle)

class ChoicePaletteWindowController: NSWindowController {
    var isClosingWindowAfterPerformingCommand = 0

    internal static func showChoicePalette(_ window: NSWindow?, placeholder: String, allowsEmptySelection: Bool = false, allowsMultipleSelection: Bool = false, items: [ChoicePaletteItemType], willDisplayTableCellViewHandler: ((ChoicePaletteItemType, NSTableCellView) -> Void)? = nil, completionHandler: @escaping ((String?, ([ChoicePaletteItemType])?) -> Void)) {
        let choicePaletteWindowController = choicePaletteStoryboard.instantiateInitialController() as! ChoicePaletteWindowController

        choicePaletteWindowController.loadWindow()
        
        let hostWindowLevel = window?.level ?? .normal
        if let palletWindow = choicePaletteWindowController.window, palletWindow.level < hostWindowLevel {
            palletWindow.level = hostWindowLevel + 1
        }

        if let viewController = choicePaletteWindowController.choicePaletteViewController {
            viewController.willDisplayTableCellViewHandler = willDisplayTableCellViewHandler
            viewController.placeholderString = placeholder
            viewController.setChoicePaletteItems(items)
            viewController.allowsEmptySelection = allowsEmptySelection
            viewController.allowsMutlipleSelection = allowsMultipleSelection
            choicePaletteWindowController.window?.layoutIfNeeded()
            viewController.completionHandler = { text, choicePaletteItem in
                completionHandler(text, choicePaletteItem)
                choicePaletteWindowController.isClosingWindowAfterPerformingCommand += 1
                choicePaletteWindowController.window?.close()
                choicePaletteWindowController.isClosingWindowAfterPerformingCommand -= 1
            }
        }

        choicePaletteWindowController.window?.centerOnWindow(window)
        choicePaletteWindowController.showWindow(nil)
    }

    var choicePaletteViewController: ChoicePaletteViewController? {
        return contentViewController as? ChoicePaletteViewController
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: window)
    }

    @objc func windowDidResignKey(_: Notification) {
        if isClosingWindowAfterPerformingCommand == 0 {
            choicePaletteViewController?.performChoicePaletteItem(nil, items: nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
