//
//  OutlineEditorWindow.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/5/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

var TabbedWindowsKey = "tabbedWindows"

extension Notification.Name {
    static let isTabbedWindowDidChange = Notification.Name("isTabbedWindowDidChange")
}

class OutlineEditorWindow: NSWindowTabbedBase {
    var lastTabbedWindows: [NSWindow]?

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing bufferingType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: bufferingType, defer: flag)
        addObserver(self, forKeyPath: TabbedWindowsKey, options: [], context: &TabbedWindowsKey)
        if #available(OSX 10.12, *) {
            DispatchQueue.main.async { [weak self] in
                self?.lastTabbedWindows = self?.tabbedWindows
            }
        }
        if #available(OSX 11.0, *) {
            //self.titlebarAppearsTransparent = true
        }
    }

    deinit {
        removeObserver(self, forKeyPath: TabbedWindowsKey, context: &TabbedWindowsKey)
    }

    var isFloatingWindow: Bool {
        get {
            level == .floating
        }
        set {
            if newValue {
                level = .floating
            } else {
                level = .normal
            }
            invalidateRestorableState()
        }
    }
    
    @IBAction func toggleFloating(_ sender: Any?) {
        isFloatingWindow.toggle()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if context == &TabbedWindowsKey {
            let last = lastTabbedWindows
            DispatchQueue.main.async {
                if let windows = last {
                    for each in windows {
                        each.windowController?.synchronizeWindowTitleWithDocumentName()
                    }
                }
            }
            synchronizeAllTitles()
            if #available(OSX 10.12, *) {
                lastTabbedWindows = tabbedWindows
            }
            
            NotificationCenter.default.post(name: .isTabbedWindowDidChange, object: self)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    var isTabbedWindow: Bool {
        if #available(OSX 10.12, *) {
            if let tabbedWindows = tabbedWindows, tabbedWindows.count > 0 {
                return true
            }
        }
        return false
    }

    var isTabbedWindowWithSingleDocument: Bool {
        if #available(OSX 10.12, *) {
            if isTabbedWindow {
                let document = windowController?.document as? NSDocument
                for each in tabbedWindows! {
                    if document != each.windowController?.document as? NSDocument {
                        return false
                    }
                }
                return true
            }
        }
        return false
    }

    @available(OSX 10.12, *)
    @IBAction override func toggleTabBar(_ sender: Any?) {
        super.toggleTabBar(sender)
        synchronizeAllTitles()
    }

    @available(OSX 10.12, *)
    override func addTabbedWindow(_ window: NSWindow, ordered: NSWindow.OrderingMode) {
        super.addTabbedWindow(window, ordered: ordered)
        synchronizeAllTitles()
    }

    func synchronizeAllTitles() {
        if #available(OSX 10.12, *) {
            for each in tabbedWindows ?? [] {
                if each != self {
                    each.windowController?.synchronizeWindowTitleWithDocumentName()
                }
            }
            self.windowController?.synchronizeWindowTitleWithDocumentName()
        }
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(isFloatingWindow, forKey: "floating")
    }
    
    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        if coder.decodeBool(forKey: "floating") {
            isFloatingWindow = true
        }
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleFloating(_:)) {
            menuItem.state = isFloatingWindow ? .on : .off
        }
        return super.validateMenuItem(menuItem)
    }
    
}
