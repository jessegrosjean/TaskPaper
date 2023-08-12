//
//  ChoicePaletteViewController.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/12/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa
import JavaScriptCore

class ChoicePaletteViewController: NSViewController {
    @IBOutlet var textView: NSView!
    @IBOutlet var textField: NSTextField!
    @IBOutlet var dividerView: NSBox!
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var visualEffectView: NSVisualEffectView!
    @IBOutlet var scrollViewHeightLayoutConstraint: NSLayoutConstraint!

    var scrollViewMaxHeight: CGFloat = 0
    var selectionHead: Int?
    var selectionAnchor: Int?

    var allowsEmptySelection: Bool = false {
        didSet {
            tableView.allowsEmptySelection = allowsEmptySelection
        }
    }

    var allowsMutlipleSelection: Bool = false {
        didSet {
            tableView.allowsMultipleSelection = allowsMutlipleSelection
        }
    }

    var jsChoicePalette = BirchOutline.sharedContext.jsChoicePaletteClass.construct(withArguments: ["title"])!

    var completionHandler: ((String?, [ChoicePaletteItemType]?) -> Void)?
    var willDisplayTableCellViewHandler: ((ChoicePaletteItemType, NSTableCellView) -> Void)?

    func setChoicePaletteItems(_ choicePaletteItems: [ChoicePaletteItemType]) {
        let jsChoicePaletteItems = JSValue(newArrayIn: BirchOutline.sharedContext.context)
        for i in 0 ..< choicePaletteItems.count {
            jsChoicePaletteItems?.setValue(choicePaletteItems[i], at: i)
        }
        jsChoicePalette.setValue(jsChoicePaletteItems, forProperty: "choicePaletteItems")
        updateDisplay()
    }

    var filterQuery: String {
        get {
            return jsChoicePalette.forProperty("filterQuery").toString()
        }
        set(value) {
            jsChoicePalette.setValue(value, forProperty: "filterQuery")
            textField.stringValue = value
            updateDisplay()
        }
    }

    var placeholderString: String {
        get {
            return textField.placeholderString!
        }
        set(value) {
            textField.placeholderString = value
        }
    }

    var dataCellIdentifier: String = "TitleDataCell" {
        didSet {
            tableView.rowHeight = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier(dataCellIdentifier), owner: nil)!.subviews[0].fittingSize.height
        }
    }

    var topChoicePaletteItemIndex: Int? {
        let index = Int(jsChoicePalette.forProperty("topChoicePaletteItemIndex").toInt32())
        if index >= 0 {
            return index
        }
        return nil
    }

    var topChoicePaletteItemIndexSet: IndexSet {
        if let index = topChoicePaletteItemIndex {
            return IndexSet(integer: index)
        }
        return IndexSet()
    }

    var numberOfMatchingChoicePaletteItems: Int {
        return Int(jsChoicePalette.forProperty("numberOfMatchingChoicePaletteItems").toInt32())
    }

    func matchingChoicePaletteItemAtIndex(_ index: Int) -> ChoicePaletteItemType {
        let jsChoicePaletteItem = jsChoicePalette.invokeMethod("matchingChoicePaletteItemAtIndex", withArguments: [index])
        return jsChoicePaletteItem!.toObject() as! ChoicePaletteItemType
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollViewMaxHeight = scrollViewHeightLayoutConstraint.constant
        dataCellIdentifier = "TitleDataCell"
    }

    func updateDisplay() {
        tableView.reloadData()
        tableView.selectRowIndexes(topChoicePaletteItemIndexSet, byExtendingSelection: false)
        tableView.scrollRowToVisible(tableView.selectedRow)
        selectionHead = tableView.selectedRowIndexes.first
        selectionAnchor = selectionHead

        var scrollViewHeight: CGFloat = 0
        
        if numberOfMatchingChoicePaletteItems > 0 {
            dividerView.isHidden = false
            tableView.isHidden = false
            let topPadding = tableView.frameOfCell(atColumn: 0, row: 0).minY
            scrollViewHeight = tableView.frameOfCell(atColumn: 0, row: tableView.numberOfRows - 1).maxY + topPadding + 1
        } else {
            //dividerView.isHidden = true
            //tableView.isHidden = true
            scrollViewHeight = 22.0
        }

        scrollViewHeightLayoutConstraint.constant = min(scrollViewHeight, scrollViewMaxHeight)
    }

    func performChoicePaletteItem(_ string: String?, items: [ChoicePaletteItemType]?) {
        completionHandler?(string, items)
        completionHandler = nil
        filterQuery = ""
        placeholderString = ""
    }

    @IBAction func doubleClick(_: Any?) {
        if let globalLocation = NSApp.currentEvent?.locationInWindow {
            let localLocation = tableView.convert(globalLocation, from: nil)
            let clickedRow = tableView.row(at: localLocation)

            if clickedRow == tableView.selectedRow {
                performChoicePaletteItem(filterQuery, items: [matchingChoicePaletteItemAtIndex(clickedRow)])
            }
        }
    }

    override func selectAll(_: Any?) {
        selectionHead = nextValidRow(nil)
        selectionAnchor = previousValidRow(nil)
        tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
    }
}

extension ChoicePaletteViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        guard let fieldEditor = (obj as Notification).userInfo!["NSFieldEditor"] as? NSTextView, let textStorage = fieldEditor.textStorage else {
            return
        }
        filterQuery = textStorage.string
    }

    func isRowSelectable(_ row: Int) -> Bool {
        return tableView.delegate!.tableView!(tableView, selectionIndexesForProposedSelection: IndexSet(integer: row)).contains(row)
    }

    func previousValidRow(_ row: Int?) -> Int? {
        var r = (row ?? tableView.numberOfRows) - 1
        while r >= 0 {
            if isRowSelectable(r) {
                return r
            }
            r -= 1
        }
        return nil
    }

    func nextValidRow(_ row: Int?) -> Int? {
        var r = (row ?? -1) + 1
        while r < tableView.numberOfRows {
            if isRowSelectable(r) {
                return r
            }
            r += 1
        }
        return nil
    }

    func rangeSelectionIndexes() -> IndexSet {
        if !tableView.allowsMultipleSelection {
            selectionAnchor = selectionHead
        }

        if let anchor = selectionAnchor, let head = selectionHead {
            if anchor > head {
                return tableView.delegate!.tableView!(tableView, selectionIndexesForProposedSelection: IndexSet(integersIn: head ... anchor))
            } else if anchor < head {
                return tableView.delegate!.tableView!(tableView, selectionIndexesForProposedSelection: IndexSet(integersIn: anchor ... head))
            } else {
                return IndexSet(integer: anchor)
            }
        }
        return IndexSet()
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(moveToBeginningOfParagraph(_:)):
            fallthrough
        case #selector(moveUp(_:)):
            let indexes = rangeSelectionIndexes()
            let min = indexes.min()
            if !filterQuery.isEmpty, min == topChoicePaletteItemIndex, indexes.count == 1, allowsEmptySelection {
                selectionHead = nil
                selectionAnchor = nil
                tableView.selectRowIndexes(IndexSet(), byExtendingSelection: false)
            } else if let nextSelectedRow = previousValidRow(min) ?? min {
                selectionHead = nextSelectedRow
                selectionAnchor = nextSelectedRow
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(moveParagraphBackwardAndModifySelection(_:)):
            fallthrough
        case #selector(moveUpAndModifySelection(_:)):
            if let nextSelectedRow = previousValidRow(selectionHead) ?? selectionHead {
                selectionHead = nextSelectedRow
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(moveToBeginningOfDocument(_:)):
            if let nextSelectedRow = nextValidRow(nil) {
                selectionHead = nextSelectedRow
                selectionAnchor = selectionHead
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(moveToBeginningOfDocumentAndModifySelection(_:)):
            if let nextSelectedRow = nextValidRow(nil) {
                selectionHead = nextSelectedRow
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(moveToEndOfParagraph(_:)):
            fallthrough
        case #selector(moveDown(_:)):
            let max = rangeSelectionIndexes().max()
            if let nextSelectedRow = nextValidRow(max) ?? max {
                selectionHead = nextSelectedRow
                selectionAnchor = nextSelectedRow
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(moveParagraphForwardAndModifySelection(_:)):
            fallthrough
        case #selector(moveDownAndModifySelection(_:)):
            if let nextSelectedRow = nextValidRow(selectionHead) ?? selectionHead {
                selectionHead = nextSelectedRow
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(moveToEndOfDocument(_:)):
            if let nextSelectedRow = previousValidRow(nil) {
                selectionHead = nextSelectedRow
                selectionAnchor = selectionHead
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(moveToEndOfDocumentAndModifySelection(_:)):
            if let nextSelectedRow = previousValidRow(nil) {
                selectionHead = nextSelectedRow
                tableView.selectRowIndexes(rangeSelectionIndexes(), byExtendingSelection: false)
            }
            return true
        case #selector(insertNewline(_:)):
            if tableView.selectedRow != -1 || (allowsEmptySelection && !filterQuery.isEmpty) {
                var choices = [ChoicePaletteItemType]()
                for each in tableView.selectedRowIndexes {
                    choices.append(matchingChoicePaletteItemAtIndex(each))
                }
                performChoicePaletteItem(filterQuery, items: choices)
                return true
            } else {
                NSSound.beep()
                return false
            }
        case #selector(cancelOperation(_:)), #selector(insertTab(_:)), #selector(insertBacktab(_:)):
            performChoicePaletteItem(nil, items: nil)
            return true
        default:
            return false
        }
    }
}

extension ChoicePaletteViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return numberOfMatchingChoicePaletteItems
    }
}

extension ChoicePaletteViewController: NSTableViewDelegate {
    func tableView(_: NSTableView, rowViewForRow _: Int) -> NSTableRowView? {
        return ChoicePaletteRowView()
    }

    func tableView(_: NSTableView, isGroupRow row: Int) -> Bool {
        //return matchingChoicePaletteItemAtIndex(row).isGroup
        return false
    }

    func tableView(_: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        var filtered = IndexSet()
        for each in proposedSelectionIndexes {
            if matchingChoicePaletteItemAtIndex(each).isSelectable {
                filtered.insert(each)
            }
        }
        return filtered
    }

    func tableViewSelectionIsChanging(_: Notification) {
        // IsChanging is only called for mouse selection changes
        if tableView.selectedRow == -1 {
            selectionHead = nil
        } else {
            selectionHead = tableView.selectedRow
        }
        selectionAnchor = selectionHead
    }

    func tableViewSelectionDidChange(_: Notification) {
        tableView.scrollRowToVisible(tableView.selectedRow)
    }

    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        let choicePaletteItem = matchingChoicePaletteItemAtIndex(row)

        if choicePaletteItem.isGroup {
            if let cell = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier("HeaderCell"), owner: self) as? NSTableCellView {
                cell.textField?.stringValue = choicePaletteItem.title
                willDisplayTableCellViewHandler?(choicePaletteItem, cell)
                return cell
            }
        } else {
            if let cell = tableView.makeView(withIdentifier: convertToNSUserInterfaceItemIdentifier(dataCellIdentifier), owner: self) as? ChoicePaletteTableCellView {
                cell.backgroundStyle = .light
                cell.detailTextField.objectValue = nil
                if let textField = cell.titleTextField {
                    textField.textColor = NSColor.labelColor
                    textField.stringValue = choicePaletteItem.title
                    if let titleMatchIndexes = choicePaletteItem.titleMatchIndexes?.toArray() as? [Int] {
                        let attributedString = textField.attributedStringValueRemovingForegroundColor
                        for each in titleMatchIndexes {
                            attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: NSColor.selectedTextBackgroundColor.withAlphaComponent(0.5), range: NSMakeRange(each, 1))
                        }
                        textField.attributedStringValue = attributedString
                    }
                }
                let indentationLevel = choicePaletteItem.indentationLevel
                cell.indentationLayoutConstraint.constant = 3 + CGFloat(indentationLevel * 15)
                willDisplayTableCellViewHandler?(choicePaletteItem, cell)
                return cell
            }
        }
        return nil
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToNSUserInterfaceItemIdentifier(_ input: String) -> NSUserInterfaceItemIdentifier {
    return NSUserInterfaceItemIdentifier(rawValue: input)
}
