//
//  OutlineEditorViewController-Delegate.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/11/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

extension OutlineEditorViewController: NSTextViewDelegate {
    public func undoManager(for _: NSTextView) -> UndoManager? {
        return nil
    }

    public func textView(_ textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem _: UnsafeMutablePointer<Int>?) -> [String] {
        guard let textStorage = textView.textStorage, let outlineEditor = outlineEditor else {
            return words
        }

        let partialWord = textStorage.substring(with: charRange)
        if partialWord.hasPrefix("@") {
            return outlineEditor.outlineSidebar?.getAutocompleteTagsForPartialTag(partialWord) ?? words
        }

        return words
    }

    public func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(NSTextView.insertTab):
            outlineEditor?.performCommand("outline-editor:insert-tab", options: nil)
        case #selector(NSTextView.insertBacktab):
            outlineEditor?.performCommand("outline-editor:insert-backtab", options: nil)
        case #selector(NSTextView.insertNewline):
            outlineEditor?.performCommand("outline-editor:newline", options: nil)
        case #selector(NSTextView.insertNewlineIgnoringFieldEditor):
            outlineEditor?.performCommand("outline-editor:newline-without-indent", options: nil)
        case #selector(NSTextView.deleteBackward):
            if userDefaults.bool(forKey: BAllowDeleteBackwardToUnindentItems) {
                outlineEditor?.performCommand("outline-editor:backspace", options: nil)
            } else {
                return false
            }
        default:
            resetDistanceForVerticalArrowKeyMovementIfNeeded(textView, commandSelector: commandSelector)
            return false
        }
        return true
    }
    
    public func textView(_ view: NSTextView, menu: NSMenu, for event: NSEvent, at charIndex: Int) -> NSMenu? {
        if let outlineEditorView = view as? OutlineEditorView {
            let localPoint = outlineEditorView.convert(event.locationInWindow, from: nil)
            
            guard let itemPick = outlineEditorView.pickItem(localPoint) else {
                return menu
            }

            if itemPick.handleContainsPoint {
                view.setSelectedRange(NSMakeRange(charIndex, 0))
                menu.removeAllItems()
            }

            // let item = itemPick.storageItem.item

            /* if let menuItem = menu.addItemWithTitle("Focus In".localized(), action: #selector(OutlineEditorViewController.focusIn(_:)), keyEquivalent: "") {
                 menuItem.representedObject = item.id
             }

             if let menuItem = menu.addItemWithTitle("Focus Out".localized(), action: #selector(OutlineEditorViewController.focusOut(_:)), keyEquivalent: "") {
                 menuItem.representedObject = item.id
             }

             menu.addItem(NSMenuItem.separatorItem())

             menu.addItemWithTitle("Group".localized(), action: #selector(OutlineEditorViewController.groupLines(_:)), keyEquivalent: "")
             menu.addItemWithTitle("Duplicate".localized(), action: #selector(OutlineEditorViewController.duplicateLines(_:)), keyEquivalent: "")

             menu.addItem(NSMenuItem.separatorItem())

             menu.addItemWithTitle("Delete".localized(), action: #selector(OutlineEditorViewController.deleteLines(_:)), keyEquivalent: "")

             menu.addItem(NSMenuItem.separatorItem()) */

            // let menuItem = menu.addItem(withTitle: "Open in New Window".localized(), action: #selector(OutlineDocument.newWindowController), keyEquivalent: "")
            // menuItem.representedObject = item.id

            // if #available(OSX 10.12, *) {
            //    menu.addItem(withTitle: "Open in New Tab".localized(), action: #selector(self.openInNewTab(_:)), keyEquivalent: "")
            // }

            // menu.addItem(NSMenuItem.separator())
        }
        return menu
    }

    public func textViewDidChangeSelection(_: Notification) {
        selectionStack = []
        let range = outlineEditorView.selectedRange()
        outlineEditor?.moveSelectionToRange(range.location, anchorLocation: range.location + range.length)
    }
    
    public func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        if let currentEvent = NSApp.currentEvent {
            if currentEvent.modifierFlags.contains(.option) {
                textView.setSelectedRange(NSMakeRange(charIndex, 0))
                return true
            }
        }

        if let _ = link as? URL {
            return false
        }

        func openOrSelect(url: URL) {
            if FileManager.default.fileExists(atPath: url.path) {
                #if APPSTORE
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                #else
                    if NSApp.currentEvent?.modifierFlags.contains(.command) ?? false {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    } else {
                        NSWorkspace.shared.open(url)
                    }
                #endif
            } else {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("File not found", comment: "")
                alert.informativeText = NSLocalizedString("Could not find file to open at path: \(url.path)", comment: "")
                alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
                alert.beginSheetModal(for: view.window!, completionHandler: nil)
            }
        }

        guard let document = view.window?.windowController?.document as? OutlineDocument else {
            return false
        }

        if let linkText = link as? NSString {
            var path = linkText.substring(from: 0)
            
            if linkText.range(of: "file://").location == 0 {
                path = linkText.substring(from: 7)
            } else if linkText.range(of: "path:").location == 0 {
                path = linkText.substring(from: 5)
            } else {
                if let outlineEditor = outlineEditor, let item = outlineEditor.textStorage.itemAtIndex(charIndex), let linkString = link as? String {
                    return outlineEditor.clickedOnItem(item, link: linkString)
                } else {
                    return false
                }
            }
            
            if path.hasPrefix(".") {
                if let basePath = document.fileURL?.path.stringByDeletingLastPathComponent, !document.isDraft {
                    path = NSString(string: basePath.stringByAppendingPathComponent(path)).standardizingPath
                } else {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("You must fist save your document.", tableName: "RelativeLinksAlert", comment: "message text")
                    alert.informativeText = NSLocalizedString("Once you have saved your document relative file links will be opened relative to your document's save location.", tableName: "RelativeLinksAlert", comment: "informative text")
                    alert.addButton(withTitle: NSLocalizedString("OK", tableName: "RelativeLinksAlert", comment: "button"))
                    alert.beginSheetModal(for: view.window!, completionHandler: nil)
                    return true
                }
            }
            
            let expandedPath = (path as NSString).expandingTildeInPath
            
            // Path might be URL encoded, or not. First if will fail if it is not URL encoded.
            // /a%CC%82.taskpaper
            // /â.taskpaper
            
            if let url = URL(string: "file://\(expandedPath)") {
                openOrSelect(url: url)
            } else {
                openOrSelect(url: URL(fileURLWithPath: expandedPath))
            }
            
            return true
        }
        
        return false
    }

    func resetDistanceForVerticalArrowKeyMovementIfNeeded(_ textView: NSTextView, commandSelector: Selector) {
        let moveUpOrDown = commandSelector == #selector(NSTextView.moveUp) || commandSelector == #selector(NSTextView.moveDown)
        let moveUpOrDownAndModify = commandSelector == #selector(NSTextView.moveUpAndModifySelection) || commandSelector == #selector(NSTextView.moveDownAndModifySelection)

        if moveUpOrDown || moveUpOrDownAndModify {
            let textStorage = textView.textStorage!
            let selectedRange = textView.selectedRange
            let paragraphRange = textStorage.paragraphRange(for: selectedRange)

            if selectedRange.length == 0, paragraphRange.location == selectedRange.location {
                let keyPath = "_sharedData._distanceForVerticalArrowKeyMovement"
                do {
                    try ObjC.catchException {
                        if let distance = textView.value(forKeyPath: keyPath) as? CGFloat {
                            if distance == -1 || moveUpOrDownAndModify {
                                textView.setValue(0, forKeyPath: keyPath)
                            }
                        }
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
}

extension OutlineEditorViewController: OutlineEditorViewHandleDelegate {
    func outlineEditor(_: OutlineEditorView, clickedItemHandle item: ItemType) -> Bool {
        if let event = NSApp.currentEvent, let outlineEditor = outlineEditor {
            if event.modifierFlags.contains(.option) {
                if outlineEditor.focusedItem === item {
                    outlineEditor.performCommand("outline-editor:focus-out", options: nil)
                } else {
                    outlineEditor.performCommand("outline-editor:focus-in", options: ["item": item])
                }
            } else {
                outlineEditor.performCommand("outline-editor:fold", options: ["item": item, "allowFoldAncestor": false])
            }
            return true
        }
        return false
    }
}
