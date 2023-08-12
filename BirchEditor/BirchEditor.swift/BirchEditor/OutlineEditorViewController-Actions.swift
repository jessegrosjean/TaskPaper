//
//  OutlineEditorViewController-Actions.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/12/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

extension OutlineEditorViewController {
    // Hoisting

    @IBAction func goHome(_: Any?) {
        if let outlineEditor = outlineEditor {
            outlineEditor.hoistedItem = outlineEditor.outline.root
        }
    }

    @IBAction func hoist(_: Any?) {
        outlineEditor?.performCommand("outline-editor:hoist", options: nil)
    }

    @IBAction func unhoist(_: Any?) {
        outlineEditor?.performCommand("outline-editor:unhoist", options: nil)
    }

    @IBAction func focusIn(_: Any?) {
        outlineEditor?.performCommand("outline-editor:focus-in", options: nil)
    }

    @IBAction func focusOut(_: Any?) {
        outlineEditor?.performCommand("outline-editor:focus-out", options: nil)
    }

    @IBAction func focusProject(_: Any?) {}

    // Folding

    @IBAction func fold(_: Any?) {
        outlineEditor?.performCommand("outline-editor:fold", options: nil)
    }

    @IBAction func foldCompletely(_: Any?) {
        outlineEditor?.performCommand("outline-editor:fold-completely", options: nil)
    }

    @IBAction func expand(_: Any?) {
        outlineEditor?.performCommand("outline-editor:expand", options: nil)
    }

    @IBAction func expandCompletely(_: Any?) {
        outlineEditor?.performCommand("outline-editor:expand-completely", options: nil)
    }

    @IBAction func expandAll(_: Any?) {
        outlineEditor?.performCommand("outline-editor:expand-all", options: nil)
    }

    @IBAction func collapse(_: Any?) {
        outlineEditor?.performCommand("outline-editor:collapse", options: nil)
    }

    @IBAction func collapseCompletely(_: Any?) {
        outlineEditor?.performCommand("outline-editor:collapse-completely", options: nil)
    }

    @IBAction func collapseAll(_: Any?) {
        outlineEditor?.performCommand("outline-editor:collapse-all", options: nil)
    }

    @IBAction func decreaseExpansionLevel(_: Any?) {
        outlineEditor?.performCommand("outline-editor:decrease-expansion-level", options: nil)
    }

    @IBAction func increaseExpansionLevel(_: Any?) {
        outlineEditor?.performCommand("outline-editor:increase-expansion-level", options: nil)
    }

    @IBAction func copyDisplayed(_: Any?) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        for each in outlineEditorView.writablePasteboardTypes {
            _ = outlineEditorView.writeSelectionToPasteboard(pasteboard, type: each, onlyDisplayed: true)
        }
    }

    // Formatting

    @IBAction func toggleBold(_: Any?) {
        outlineEditor?.performCommand("outline-editor:toggle-bold", options: nil)
    }

    @IBAction func toggleItalic(_: Any?) {
        outlineEditor?.performCommand("outline-editor:toggle-italic", options: nil)
    }

    @IBAction func clearFormatting(_: Any?) {
        outlineEditor?.performCommand("outline-editor:clear-formatting", options: nil)
    }

    // Moving Lines

    @IBAction func moveLineRight(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-lines-right", options: nil)
    }

    @IBAction func moveLineLeft(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-lines-left", options: nil)
    }

    @IBAction func moveLineUp(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-lines-up", options: nil)
    }

    @IBAction func moveLineDown(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-lines-down", options: nil)
    }

    @IBAction func groupLines(_: Any?) {
        outlineEditor?.performCommand("outline-editor:group-lines", options: nil)
    }

    @IBAction func duplicateLines(_: Any?) {
        outlineEditor?.performCommand("outline-editor:duplicate-lines", options: nil)
    }

    @IBAction func deleteLines(_: Any?) {
        if userDefaults.bool(forKey: BShowPoofAnimationOnDelete) {
            let localRect = outlineEditorView.rectForRange(outlineEditorView.selectedRange())
            let windowRect = outlineEditorView.convert(localRect, to: nil)
            if let window = outlineEditorView.window {
                let screenRect = window.convertToScreen(windowRect)
                let effect = NSAnimationEffect(rawValue: NSAnimationEffect.poof.rawValue)
                effect?.show(centeredAt: screenRect.center, size: NSSize(width: 50, height: 50))
            }
        }
        outlineEditor?.performCommand("outline-editor:delete-lines", options: nil)
    }

    // Moving Branches

    @IBAction func moveBranchesRight(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-branches-right", options: nil)
    }

    @IBAction func moveBranchesLeft(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-branches-left", options: nil)
    }

    @IBAction func moveBranchesUp(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-branches-up", options: nil)
    }

    @IBAction func moveBranchesDown(_: Any?) {
        outlineEditor?.performCommand("outline-editor:move-branches-down", options: nil)
    }

    
    // Tags

    @IBAction func clearTags(_: Any?) {
        outlineEditor?.performCommand("outline-editor:remove-tags", options: nil)
    }

    @IBAction func tagWith(_: Any?) {
        outlineEditor?.performCommand("outline-editor:tag-with", options: nil)
    }

    // Selection

    @IBAction func selectSentence(_: Any?) {
        outlineEditor?.performCommand("outline-editor:select-sentence", options: nil)
    }

    @IBAction override open func selectParagraph(_: Any?) {
        outlineEditor?.performCommand("outline-editor:select-item", options: nil)
    }

    @IBAction func selectBranch(_: Any?) {
        outlineEditor?.performCommand("outline-editor:select-branch", options: nil)
    }

    @IBAction func expandSelection(_ sender: Any?) {
        let original = outlineEditorView.selectedRange()
        var newSelectionStack = selectionStack

        outlineEditorView.selectWord(sender)

        if NSEqualRanges(original, outlineEditorView.selectedRange()) {
            selectSentence(sender)
            if NSEqualRanges(original, outlineEditorView.selectedRange()) {
                selectParagraph(sender)
                if NSEqualRanges(original, outlineEditorView.selectedRange()) {
                    selectBranch(sender)
                    if NSEqualRanges(original, outlineEditorView.selectedRange()) {
                        outlineEditorView.selectAll(sender)
                    }
                }
            }
        }

        if !NSEqualRanges(original, outlineEditorView.selectedRange()) {
            newSelectionStack.append(original)
        }

        selectionStack = newSelectionStack
    }

    @IBAction func contractSelection(_: Any?) {
        var newSelectionStack = selectionStack
        if let previousRange = newSelectionStack.last {
            newSelectionStack.removeLast()
            outlineEditorView.selectedRange = previousRange
            selectionStack = newSelectionStack
        }
    }
    
    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if let action = menuItem.action {
            switch action {
            case #selector(copyDisplayed(_:)):
                return outlineEditorView.selectedRange().length > 0
            default:
                return true
            }
        } else {
            return true
        }
    }

}

// Helper function inserted by Swift 4.2 migrator.
private func convertFromNSPasteboardPasteboardTypeArray(_ input: [NSPasteboard.PasteboardType]) -> [String] {
    return input.map { key in key.rawValue }
}
