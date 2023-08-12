//
//  NativeWeakEditor.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/30/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(OSX)
    import Cocoa
#endif

import BirchOutline
import EventKit
import JavaScriptCore

@objc protocol NativeOutlineEditor: JSExport {
    var isEditing: Bool { get }
    var visibleRect: CGRect { get }
    var scrollPoint: CGPoint { get set }

    var selectedRange: NSRange { get set }
    func selectWord()
    func selectSentence()
    func expandSelection()
    func contractSelection()

    func getRectForRange(_ range: NSRange) -> CGRect
    func getCharacterIndexForPoint(_ point: CGPoint) -> Int
    func scrollRangeToVisible(_ range: NSRange)

    func invalidateRestorableState()

    func beginEditing()
    func replaceCharactersInRange(_ range: NSRange, withString: String)
    func invalidateRange(_ range: NSRange)
    func endEditing()
    func focus()

    func importReminders(callback: JSValue)
    func importReminderCopies(callback: JSValue)
    func exportToReminders(callback: JSValue)
    func exportCopyToReminders(callback: JSValue)

    func getItemAttributesFromUser(_ placeholder: String, callback: JSValue)
    func getDateFromUser(_ placeholder: String, dateStringTemplate: String?, callback: JSValue)
}

class OutlineEditorWeakProxy: NSObject {
    weak var outlineEditor: OutlineEditor?
    var isEditingCount: UInt = 0

    init(outlineEditor: OutlineEditor) {
        self.outlineEditor = outlineEditor
        super.init()
    }
}

extension OutlineEditorWeakProxy: NativeOutlineEditor {
    var isEditing: Bool {
        return isEditingCount > 0
    }

    var outlineEditorView: NSTextView? {
        return outlineEditor?.outlineEditorViewController?.outlineEditorView
    }

    var visibleRect: CGRect {
        assert(!isEditing, "Dont get visibleRect when editing")
        return outlineEditorView?.enclosingScrollView?.documentVisibleRect ?? CGRect(x: 0, y: 0, width: 0, height: 0)
    }

    var scrollPoint: CGPoint {
        get {
            assert(!isEditing, "Dont get scrollPoint when editing")
            return visibleRect.origin
        }
        set(point) {
            assert(!isEditing, "Dont set scrollPoint when editing")
            if let textView = outlineEditorView {
                textView.enclosingScrollView?.contentView.scroll(to: point)
            }
        }
    }

    var selectedRange: NSRange {
        get {
            return outlineEditorView?.selectedRange ?? NSRange(location: 0, length: 0)
        }
        set(range) {
            assert(!isEditing, "Dont set selectedRange when editing")
            outlineEditorView?.setSelectedRange(range)
        }
    }

    func selectWord() {
        outlineEditorView?.selectWord(nil)
    }

    func selectSentence() {
        outlineEditorView?.selectSentence()
    }

    func expandSelection() {
        outlineEditor?.outlineEditorViewController?.expandSelection(nil)
    }

    func contractSelection() {
        outlineEditor?.outlineEditorViewController?.contractSelection(nil)
    }

    func getRectForRange(_ range: NSRange) -> CGRect {
        assert(!isEditing, "Dont set getRectForRange when editing")
        if let textView = outlineEditorView {
            return textView.rectForRange(range)
        }
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }

    func getCharacterIndexForPoint(_ point: CGPoint) -> Int {
        if let textView = outlineEditorView {
            return textView.characterIndexForLocalPoint(point, partialFraction: nil)
        }
        return 0
    }

    func scrollRangeToVisible(_ range: NSRange) {
        assert(!isEditing, "Dont set scrollRangeToVisible when editing")
        if let textView = outlineEditorView {
            if range.location == NSNotFound {
                textView.scrollRangeToVisible(textView.selectedRange)
            } else {
                textView.scrollRangeToVisible(range)
            }
        }
    }

    func invalidateRestorableState() {
        outlineEditor?.outlineEditorViewController?.parent?.invalidateRestorableState()
    }

    func beginEditing() {
        isEditingCount += 1
        outlineEditor?.textStorage.beginEditing()
    }

    func replaceCharactersInRange(_ range: NSRange, withString string: String) {
        outlineEditor?.textStorage.replaceCharacters(in: range, with: string)
    }

    func invalidateRange(_ range: NSRange) {
        guard let textStorage = outlineEditor?.textStorage else {
            return
        }

        if !textStorage.isUpdatingNative {
            // Problem is that it breaks selection in some case. For example if do a word delete without this check
            // the selection will end up in wrong place... I guess the setAttributes call becomes part of edit, and native
            // behavior is to move selectioin to end of edit.
            //
            // Maybe proper longterm soluiton is to move all seletion management into javascript editor. But that could get complex
            // for marked input cases, right to left text edits, etc. So instead just skip this. Seems to work fine this way anyway.
            // since native editor edits are mostly simple typing that doesn't generally invalidate styoles..

            textStorage.invalidateRange(range)
        }
    }

    func endEditing() {
        isEditingCount -= 1
        outlineEditor?.textStorage.endEditing()
    }

    func focus() {
        if let textView = outlineEditorView {
            textView.window?.makeFirstResponder(textView)
        }
    }

    func importReminders(callback: JSValue) {
        guard let outlineEditor = outlineEditor else {
            _ = callback.selfOrNil()?.call(withArguments: [false])
            return
        }

        if !userDefaults.bool(forKey: BRemindersSuppressImportRemindersAlert) {
            let alert = NSAlert()
            alert.showsSuppressionButton = true
            alert.messageText = NSLocalizedString("Imported reminders will be removed from Reminders.app", tableName: "Reminders", comment: "message text")
            alert.runModal()
            if alert.suppressionButton?.state == .on {
                userDefaults.set(true, forKey: BRemindersSuppressImportRemindersAlert)
            }
        }

        let placeholder = NSLocalizedString("Import Reminders", tableName: "Reminders", comment: "placeholder text")
        let useDefaultList = userDefaults.bool(forKey: BRemindersAlwaysUseDefaultList)
        let allowCompletedReminders = userDefaults.bool(forKey: BRemindersAllowsImportOfCompletedItems)

        RemindersStore.showRemindersPalette(outlineEditor, placeholder: placeholder, useDefaultList: useDefaultList, allowCompletedReminders: allowCompletedReminders, allowsMultipleSelection: true) { _, reminders, error in
            if let error = error {
                NSApp.presentError(error)
                _ = callback.selfOrNil()?.call(withArguments: [false])
                return
            }

            if let reminders = reminders {
                let outline = outlineEditor.outline
                let items = reminders.map { RemindersStore.createItem($0, outline: outline) }
                let nextSibling = outlineEditor.displayedSelectedItems.first
                let parent = nextSibling?.parent ?? outlineEditor.hoistedItem
                parent.insertChildren(items, beforeSibling: nextSibling ?? parent.firstChild)
                outlineEditor.moveSelectionToItems(items.first!, headOffset: 0, anchorItem: items.last, anchorOffset: -1)

                do {
                    let nonLossyImports = reminders.filter { !$0.isLossyOnImport }
                    if reminders.count != nonLossyImports.count {
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("Some reminders were not fully imported", tableName: "Reminders", comment: "message text")
                        alert.informativeText = NSLocalizedString("Reminders with location based alarms (or recurrence rules) cannot be fully imported. Would you like “Keep” or “Remove” these reminders in Reminders.app?", tableName: "Reminders", comment: "informative text")
                        alert.addButton(withTitle: NSLocalizedString("Keep", tableName: "Reminders", comment: "button"))
                        alert.addButton(withTitle: NSLocalizedString("Remove", tableName: "Reminders", comment: "button"))
                        let response = alert.runModal()
                        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                            try RemindersStore.remove(nonLossyImports)
                        } else {
                            try RemindersStore.remove(reminders)
                        }
                    } else {
                        try RemindersStore.remove(reminders)
                    }
                } catch {
                    NSApp.presentError(error)
                }

                _ = callback.selfOrNil()?.call(withArguments: [true])
            } else {
                _ = callback.selfOrNil()?.call(withArguments: [false])
            }
        }
    }

    func importReminderCopies(callback: JSValue) {
        guard let outlineEditor = outlineEditor else {
            _ = callback.selfOrNil()?.call(withArguments: [false])
            return
        }

        let placeholder = NSLocalizedString("Import Reminder Copies", tableName: "Reminders", comment: "placeholder text")
        let useDefaultList = userDefaults.bool(forKey: BRemindersAlwaysUseDefaultList)
        let allowCompletedReminders = userDefaults.bool(forKey: BRemindersAllowsImportOfCompletedItems)

        RemindersStore.showRemindersPalette(outlineEditor, placeholder: placeholder, useDefaultList: useDefaultList, allowCompletedReminders: allowCompletedReminders, allowsMultipleSelection: true) { _, reminders, error in
            if let error = error {
                NSApp.presentError(error)
                _ = callback.selfOrNil()?.call(withArguments: [false])
                return
            }

            if let reminders = reminders {
                let outline = outlineEditor.outline
                let items = reminders.map { RemindersStore.createItem($0, outline: outline) }
                let nextSibling = outlineEditor.displayedSelectedItems.first
                let parent = nextSibling?.parent ?? outlineEditor.hoistedItem
                parent.insertChildren(items, beforeSibling: nextSibling ?? parent.firstChild)
                outlineEditor.moveSelectionToItems(items.first!, headOffset: 0, anchorItem: items.last, anchorOffset: -1)
                _ = callback.selfOrNil()?.call(withArguments: [true])
            } else {
                _ = callback.selfOrNil()?.call(withArguments: [false])
            }
        }
    }

    func exportToReminders(callback: JSValue) {
        guard let outlineEditor = outlineEditor else {
            _ = callback.selfOrNil()?.call(withArguments: [false])
            return
        }

        let placeholder = NSLocalizedString("Export to Reminders", tableName: "Reminders", comment: "placeholder text")
        let useDefaultList = userDefaults.bool(forKey: BRemindersAlwaysUseDefaultList)

        RemindersStore.showReminderCalendarsPalette(outlineEditor, placeholder: placeholder, useDefaultList: useDefaultList, completionHandler: { _, calendars, error in
            if let error = error {
                NSApp.presentError(error)
                _ = callback.selfOrNil()?.call(withArguments: [false])
                return
            }

            if let calendar = calendars?[0] {
                let outline = outlineEditor.outline
                let items = JSValue.getCommonAncestors(outlineEditor.displayedSelectedItems)
                var reminders = [EKReminder]()

                for each in items {
                    reminders.append(RemindersStore.createReminder(each, outline: outline, reminderCalendar: calendar))
                }

                do {
                    try RemindersStore.save(reminders)
                } catch {
                    NSApp.presentError(error)
                    _ = callback.selfOrNil()?.call(withArguments: [true])
                    return
                }

                outline.groupUndo {
                    outline.groupChanges {
                        for each in items {
                            each.removeFromParent()
                        }
                    }
                }

                _ = callback.selfOrNil()?.call(withArguments: [true])
            } else {
                _ = callback.selfOrNil()?.call(withArguments: [false])
            }
        })
    }

    func exportCopyToReminders(callback: JSValue) {
        guard let outlineEditor = outlineEditor else {
            _ = callback.selfOrNil()?.call(withArguments: [false])
            return
        }

        let placeholder = NSLocalizedString("Export Copy to Reminders", tableName: "Reminders", comment: "placeholder text")
        let useDefaultList = userDefaults.bool(forKey: BRemindersAlwaysUseDefaultList)

        RemindersStore.showReminderCalendarsPalette(outlineEditor, placeholder: placeholder, useDefaultList: useDefaultList, completionHandler: { _, calendars, error in
            if let error = error {
                NSApp.presentError(error)
                _ = callback.selfOrNil()?.call(withArguments: [false])
                return
            }

            if let calendar = calendars?[0] {
                let outline = outlineEditor.outline
                let items = JSValue.getCommonAncestors(outlineEditor.displayedSelectedItems)
                var reminders = [EKReminder]()

                for each in items {
                    reminders.append(RemindersStore.createReminder(each, outline: outline, reminderCalendar: calendar))
                }

                do {
                    try RemindersStore.save(reminders)
                } catch {
                    NSApp.presentError(error)
                    _ = callback.selfOrNil()?.call(withArguments: [true])
                    return
                }

                _ = callback.selfOrNil()?.call(withArguments: [true])
            } else {
                _ = callback.selfOrNil()?.call(withArguments: [false])
            }
        })
    }

    func getItemAttributesFromUser(_ placeholder: String, callback: JSValue) {
        guard
            let outlineEditor = outlineEditor,
            let sidebar = outlineEditor.outlineSidebar else {
            _ = callback.selfOrNil()?.call(withArguments: [])
            return
        }

        let choices = [sidebar.tagsGroup.cloneBranch()]
        let items = flattenChoicePaletteItemBranches(choices).filter { item in
            item.type != "tag-value"
        }

        ChoicePaletteWindowController.showChoicePalette(outlineEditor.outlineEditorViewController?.view.window, placeholder: placeholder, allowsEmptySelection: true, allowsMultipleSelection: true, items: items, completionHandler: { string, choicePaletteItems in
            if let string = string, let choices = choicePaletteItems {
                let tags = choices.map { (choicePaletteItem) -> String in
                    if let tagName = choicePaletteItem.representedObject as? String {
                        let name = tagName[tagName.index(after: tagName.startIndex)...]
                        let attributeName = "data-\(name)"
                        return attributeName
                    } else {
                        return ""
                    }
                }
                if tags.isEmpty {
                    var tagName = string
                    if tagName.hasPrefix("@") {
                        tagName = String(tagName[tagName.index(after: tagName.startIndex)...])
                    }
                    _ = callback.selfOrNil()?.call(withArguments: [["data-\(tagName)"]])
                } else {
                    _ = callback.selfOrNil()?.call(withArguments: [tags])
                }
            } else {
                _ = callback.selfOrNil()?.call(withArguments: [])
            }
        })
    }

    func getDateFromUser(_ placeholder: String, dateStringTemplate: String?, callback: JSValue) {
        DatePickerWindowController.showDatePicker(outlineEditor?.outlineEditorViewController?.view.window, placeholder: placeholder, dateStringTemplate: dateStringTemplate) { date in
            if let date = date {
                _ = callback.selfOrNil()?.call(withArguments: [date])
            } else {
                _ = callback.selfOrNil()?.call(withArguments: [])
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSControlStateValue(_ input: NSControl.StateValue) -> Int {
    return input.rawValue
}
