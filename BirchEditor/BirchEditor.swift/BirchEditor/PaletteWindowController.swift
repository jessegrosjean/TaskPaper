//
//  PaletteWindowController.swift
//  Birch
//
//  Created by Jesse Grosjean on 10/28/16.
//
//

class PaletteWindowController: NSWindowController {
    override func windowDidLoad() {
        super.windowDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: window)
    }

    @objc func windowDidResignKey(_: Notification) {
        paletteViewController?.performAction(nil)
    }

    var paletteViewController: PaletteViewController? {
        return contentViewController as? PaletteViewController
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
