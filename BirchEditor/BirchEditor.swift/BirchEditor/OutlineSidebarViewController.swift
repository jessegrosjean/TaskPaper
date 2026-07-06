//
//  OutlineSidebarViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/26/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa
import JavaScriptCore

let SidebarAutosaveName = "Sidebar"

class OutlineSidebarViewController: NSViewController, OutlineEditorHolderType, StylesheetHolder {
    @IBOutlet var backgroundView: NSVisualEffectView!
    @IBOutlet var sidebarView: OutlineSidebarView!

    var sidebarSubscriptions: [DisposableType]?
    var syncingToJSSidebar = 0
    let homeSpacerItem = NSObject()

    func isSpacerItem(_ item: Any?) -> Bool {
        return (item as AnyObject?) === homeSpacerItem
    }

    override func viewDidLoad() {
        sidebarView.registerForDraggedTypes(ItemPasteboardUtilities.readablePasteboardTypes)
        sidebarView.setDraggingSourceOperationMask(.every, forLocal: false)
        sidebarView.setDraggingSourceOperationMask(.every, forLocal: true)
        let menu = NSMenu()
        menu.delegate = self
        sidebarView.menu = menu

        if userDefaults.bool(forKey: BSidebarFontSizeFollowsSystemPreferences) {
            sidebarView.rowSizeStyle = .default
        }
    }

    deinit {
        // deinit is nonisolated, but view controllers deallocate on the main
        // thread with their window hierarchy.
        MainActor.assumeIsolated {
            outlineEditor = nil
            if let subscriptions = sidebarSubscriptions {
                for each in subscriptions {
                    each.dispose()
                }
            }
        }
    }

    var styleSheet: StyleSheet? {
        didSet {
            if let computedStyle = styleSheet?.computedStyleForElement("sidebar") {
                view.superview?.appearance = computedStyle.allValues[.appearance] as? NSAppearance
            }
            // The spacer row height derives from the stylesheet's item indent.
            if let sidebarView = sidebarView, sidebarView.numberOfRows > 0 {
                sidebarView.noteHeightOfRows(withIndexesChanged: IndexSet(integer: 0))
            }
        }
    }

    weak var outlineEditor: OutlineEditorType? {
        didSet {
            if let subscriptions = sidebarSubscriptions {
                for each in subscriptions {
                    each.dispose()
                }
            }

            if let outlineEditor = outlineEditor as? OutlineEditor {
                sidebarSubscriptions = []

                if let sidebar = outlineEditor.outlineSidebar {
                    sidebarSubscriptions?.append(sidebar.onDidChangeSelection { [weak self] in
                        self?.updateSelectionFromJS()
                    })

                    sidebarSubscriptions?.append(sidebar.onDidChangeItems { [weak self, weak sidebarView, weak sidebar] in
                        guard let sidebarView = sidebarView, let sidebar = sidebar else {
                            return
                        }

                        @MainActor func reloadIfNeeded(_ item: OutlineSidebarItem) {
                            if item.childrenChanged {
                                sidebarView.reloadItem(item, reloadChildren: true)
                                sidebarView.reloadItem(item)
                                if item.becameParent {
                                    sidebarView.expandItem(item)
                                }

                                if item.isGroup, item.attributesChanged {
                                    // Hack because of http://stackoverflow.com/questions/40407922/how-to-make-nsoutlineview-reload-group-items
                                    sidebarView.reloadData()
                                }

                                return
                            } else if item.attributesChanged {
                                sidebarView.reloadItem(item)
                                if item.isGroup {
                                    // Hack because of http://stackoverflow.com/questions/40407922/how-to-make-nsoutlineview-reload-group-items
                                    sidebarView.reloadData()
                                }
                            }

                            if item.branchChanged {
                                for each in item.children {
                                    reloadIfNeeded(each as! OutlineSidebarItem)
                                }
                                return
                            }

                            return
                        }

                        self?.syncingToJSSidebar += 1
                        sidebarView.beginUpdates()
                        if let rootItem = sidebar.rootItem {
                            reloadIfNeeded(rootItem)
                        }

                        sidebarView.endUpdates()
                        self?.updateSelectionFromJS()
                        self?.syncingToJSSidebar -= 1
                        self?.view.window?.windowController?.synchronizeWindowTitleWithDocumentName()
                    })

                    sidebarView.beginUpdates()
                    sidebarView.reloadData()
                    if userDefaults.object(forKey: "NSOutlineView Items \(SidebarAutosaveName)") == nil {
                        sidebarView.expandItem(sidebar.projectsGroup)
                        sidebarView.expandItem(sidebar.searchesGroup)
                        sidebarView.expandItem(sidebar.tagsGroup)
                    }
                    sidebarView.autosaveName = SidebarAutosaveName
                    sidebarView.endUpdates()
                    updateSelectionFromJS()
                }
            } else {
                sidebarView.delegate = nil
                sidebarView.dataSource = nil
                sidebarView.reloadData()
            }
        }
    }

    func updateSelectionFromJS() {
        if let sidebar = outlineEditor?.outlineSidebar, let sidebarView = sidebarView {
            var selectItem = sidebar.selectedItem
            if sidebarView.row(forItem: selectItem) == -1 {
                for each in sidebar.selectedItem.ancestors.reversed() {
                    if sidebarView.row(forItem: each) != -1, each.isSelectable {
                        selectItem = each as? OutlineSidebarItem
                        break
                    }
                }
            }
            syncingToJSSidebar += 1
            let row = sidebarView.row(forItem: selectItem)
            sidebarView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            syncingToJSSidebar -= 1
        }
    }

    @IBAction func singleAction(_: Any?) {
        outlineEditor?.outlineSidebar?.singleAction()
    }

    @IBAction func doubleAction(_: Any?) {
        outlineEditor?.outlineSidebar?.doubleAction()
    }

    override func doCommand(by aSelector: Selector) {
        switch aSelector {
        case #selector(insertNewline(_:)):
            view.window?.selectNextKeyView(self)
        case #selector(deleteBackward(_:)):
            super.doCommand(by: aSelector)
        default:
            super.doCommand(by: aSelector)
        }
    }

    @objc func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if let action = menuItem.action {
            switch action {
            case #selector(editSearch(_:)):
                return searchItemForSender(menuItem) != nil
            case #selector(deleteSearch(_:)):
                return searchItemForSender(menuItem) != nil
            default:
                return true
            }
        } else {
            return true
        }
    }
}

extension OutlineSidebarViewController: NSOutlineViewDataSource {
    func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? OutlineSidebarItem {
            return item.children[index]
        }        
        if index == 0 {
            return homeSpacerItem
        }
        return outlineEditor!.outlineSidebar!.rootItem!.children[index - 1]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return self.outlineView(outlineView, numberOfChildrenOfItem: item) > 0
    }

    func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if isSpacerItem(item) {
            return 0
        }
        if let item = item as? OutlineSidebarItem {
            return item.children.count
        }
        if let rootItem = outlineEditor?.outlineSidebar?.rootItem {
            return rootItem.children.count + 1 // + homeSpacerItem
        }
        return 0
    }

    func outlineView(_: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        if let sidebarItem = item as? OutlineSidebarItem, let outlineEditor = outlineEditor, sidebarItem.type == "project" {
            if let item = outlineEditor.outline.itemForID(sidebarItem.id) {
                return outlineEditor.createPasteboardItem(item)
            }
        }
        return nil
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        guard let outlineEditor = outlineEditor, let sidebarItem = item as? OutlineSidebarItem, var target = itemDropTargetFromOutlineSidebarItem(sidebarItem, proposedChildIndex: index) else {
            return NSDragOperation()
        }

        // Redirect to drop on unless dragged item is a project
        if index != NSOutlineViewDropOnItemIndex {
            let draggedItemReferences = ItemPasteboardUtilities.readItemsFromPasteboard(info.draggingPasteboard, type: .itemReference, editor: outlineEditor)

            if let items = draggedItemReferences, items.count == 1, items[0].attributeForName("data-type") == "project" {
            } else {
                let localPoint = outlineView.convert(info.draggingLocation, from: nil)
                let row = outlineView.row(at: localPoint)
                if let sidebarItem = outlineView.item(atRow: row) as? OutlineSidebarItem, let item = outlineEditor.outline.itemForID(sidebarItem.id) {
                    outlineView.setDropItem(sidebarItem, dropChildIndex: NSOutlineViewDropOnItemIndex)
                    target.parent = item
                    target.nextSibling = item.firstChild
                } else {
                    return NSDragOperation()
                }
            }
        }

        return ItemPasteboardUtilities.itemsDragOperationForDraggingInfo(info, editor: outlineEditor, parent: target.parent, nextSibling: target.nextSibling)
    }

    func outlineView(_: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if let outlineEditor = outlineEditor, let sidebarItem = item as? OutlineSidebarItem, let target = itemDropTargetFromOutlineSidebarItem(sidebarItem, proposedChildIndex: index) {
            if ItemPasteboardUtilities.itemsPerformDragOperation(info, editor: outlineEditor, parent: target.parent, nextSibling: target.nextSibling) {
                outlineEditor.outlineSidebar?.reloadImmediate()
                return true
            }
        }
        return false
    }

    func itemDropTargetFromOutlineSidebarItem(_ item: Any?, proposedChildIndex index: Int) -> (parent: ItemType, nextSibling: ItemType?)? {
        guard let sidebarItem = item as? OutlineSidebarItem, let outlineEditor = outlineEditor else {
            return nil
        }

        var parentItem = outlineEditor.outline.itemForID(sidebarItem.id)
        if parentItem == nil, sidebarItem.id == "projects" {
            parentItem = outlineEditor.outline.root
        }

        if let parentItem = parentItem {
            let projectChildren = parentItem.children.filter { each -> Bool in
                each.attributeForName("data-type") == "project"
            }

            var nextSibling: ItemType?
            if index == NSOutlineViewDropOnItemIndex {
                nextSibling = projectChildren.first
            } else {
                if index < projectChildren.count {
                    nextSibling = projectChildren[index]
                } else {
                    nextSibling = projectChildren.last?.nextSibling
                }
            }

            return (parent: parentItem, nextSibling: nextSibling)
        }

        return nil
    }
}

extension OutlineSidebarViewController: NSOutlineViewDelegate {
    func outlineView(_: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        if let item = item as? OutlineSidebarItem {
            return outlineEditor?.outlineSidebar?.persistentID(forItemID: item.id)
        }
        return nil
    }

    func outlineView(_: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        if let persistentID = object as? String, let sidebar = outlineEditor?.outlineSidebar, let sidebarItemID = sidebar.itemIDFor(persistentID: persistentID) {
            return sidebar.itemForID(sidebarItemID)
        }
        return nil
    }

    func outlineView(_: NSOutlineView, rowViewForItem _: Any) -> NSTableRowView? {
        return OutlineSidebarRowView()
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        if isSpacerItem(item) {
            return nil
        }
        if let item = item as? OutlineSidebarItem ?? outlineEditor?.outlineSidebar?.rootItem {
            var view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TextCell"), owner: self) as! NSTableCellView

            if self.outlineView(outlineView, isGroupItem: item) {
                view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as! NSTableCellView
            } else {
                // view.imageView?.image = nil
                if item.isSelectable {
                    view.textField?.textColor = NSColor.labelColor
                } else {
                    view.textField?.textColor = NSColor.red
                }
            }

            view.textField?.stringValue = item.title

            return view
        }
        return nil
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if isSpacerItem(item) {
            // Match the editor's first-line top offset (`originOffset.y` in OutlineEditorView).
            let itemIndent = CGFloat(outlineEditor?.computedItemIndent ?? 17)
            return (itemIndent / 2.0).rounded()
        }

        if userDefaults.bool(forKey: BSidebarFontSizeFollowsSystemPreferences) {
            if self.outlineView(outlineView, isGroupItem: item) {
                return outlineView.rowHeight
            } else {
                return (outlineView.rowHeight * 0.775).rounded(.awayFromZero)
            }
        } else {
            return outlineView.rowHeight
        }
    }

    func outlineView(_ outlineView: NSOutlineView, nextTypeSelectMatchFromItem startItem: Any, toItem endItem: Any, for searchString: String) -> Any? {
        let start = outlineView.row(forItem: startItem)
        let end = outlineView.row(forItem: endItem)
        var searchableItemIDs = [String]()
        var eachRow = start

        while eachRow != end {
            if eachRow >= outlineView.numberOfRows {
                eachRow = 0
                continue
            }
            if let eachItem = outlineView.item(atRow: eachRow) as? OutlineSidebarItem, eachItem.isSelectable {
                searchableItemIDs.append(eachItem.id)
            }
            eachRow += 1
        }

        return outlineEditor?.outlineSidebar?.matchItemFromIDs(searchableItemIDs, searchString: searchString)
    }

    func outlineView(_: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if isSpacerItem(item) {
            return false
        }
        if let newItem = item as? OutlineSidebarItem ?? outlineEditor?.outlineSidebar?.rootItem {
            guard let sidebar = outlineEditor?.outlineSidebar, syncingToJSSidebar == 0 else {
                return newItem.isSelectable
            }

            if sidebar.shouldSelectItem(newItem) {
                let newType = newItem.type

                let isFocused = outlineEditor?.focusedItem != nil
                let isFiltered = !(outlineEditor?.itemPathFilter ?? "").isEmpty
                let isPerformingHoist = newType == "home" || newType == "project"
                let isPerformingFilter = !isPerformingHoist
                let maintainHoistedWhenFilter = userDefaults.bool(forKey: BMaintainHoistedItemWhenFiltering)
                let maintainFilterWhenHoisting = userDefaults.bool(forKey: BMaintainItemPathFilterWhenHoisting)

                if isPerformingFilter && isFocused && maintainHoistedWhenFilter {
                    return true
                }

                if isPerformingHoist && isFiltered && maintainFilterWhenHoisting {
                    return true
                }

                if let window = sidebarView.window {
                    for each in window.tabbedWindows ?? [] {
                        if window != each, let eachOutlineEditor = (each.windowController as? OutlineEditorWindowController)?.outlineEditor, let eachSidebar = eachOutlineEditor.outlineSidebar {
                            if outlineEditor?.outline.jsOutline == eachOutlineEditor.outline.jsOutline, eachSidebar.selectedItem.id == newItem.id {
                                // if different window, but same outline and same selected item... just switch tab
                                each.makeKeyAndOrderFront(nil)
                                return false
                            }
                        }
                    }
                }

                return true
            }
        }
        return false
    }

    func outlineView(_: NSOutlineView, shouldShowOutlineCellForItem item: Any) -> Bool {
        //if let item = item as? OutlineSidebarItem ?? outlineEditor?.outlineSidebar?.rootItem {
        //    return item.id != "Birch"
        //}
        return true
    }

    func outlineViewSelectionDidChange(_: Notification) {
        guard let sidebar = outlineEditor?.outlineSidebar, syncingToJSSidebar == 0 else {
            return
        }

        if let selectedItem = sidebarView.item(atRow: sidebarView.selectedRow) as? OutlineSidebarItem {
            sidebar.selectedItem = selectedItem
        } else {
            updateSelectionFromJS()
        }
    }

    func outlineView(_: NSOutlineView, isGroupItem item: Any) -> Bool {
        if isSpacerItem(item) {
            return false
        }
        if let item = item as? OutlineSidebarItem ?? outlineEditor?.outlineSidebar?.rootItem {
            return item.isGroup
        }
        return false
    }
}

extension OutlineSidebarViewController: NSMenuDelegate {
    func newWindowController(_ sidebarItem: OutlineSidebarItem) -> OutlineEditorWindowController? {
        guard let document = sidebarView.window?.windowController?.document as? OutlineDocument else {
            return nil
        }

        let windowController = document.makeWindowController()

        document.addWindowController(windowController)

        guard
            let outlineEditor = windowController.outlineEditor,
            let outlineSidebar = outlineEditor.outlineSidebar
        else {
            return windowController
        }

        outlineSidebar.selectedItem = outlineSidebar.itemForID(sidebarItem.id)
        return windowController
    }

    @IBAction func openInNewWindow(_ sender: Any?) {
        if let sidebarItem = (sender as? NSMenuItem)?.representedObject as? OutlineSidebarItem, let windowController = newWindowController(sidebarItem) {
            windowController.window?.makeKeyAndOrderFront(nil)
        }
    }

    @IBAction func openInNewTab(_ sender: Any?) {
        guard let window = sidebarView.window else {
            return
        }
        if let sidebarItem = (sender as? NSMenuItem)?.representedObject as? OutlineSidebarItem, let windowController = newWindowController(sidebarItem) {
            window.addTabbedWindow(windowController.window!, ordered: .above)
            windowController.window?.makeKeyAndOrderFront(nil)
        }
    }

    func searchItemForSender(_ sender: Any?) -> OutlineSidebarItem? {
        if let sidebarItem = ((sender as? NSMenuItem)?.representedObject as? OutlineSidebarItem) ?? outlineEditor?.outlineSidebar?.selectedItem {
            if sidebarItem.type == "search" {
                return sidebarItem
            }
        }
        return nil
    }

    @IBAction func newSearch(_ sender: Any?) {
        guard
            let window = sidebarView.window,
            let outlineEditor = outlineEditor,
            let outlineSidebar = outlineEditor.outlineSidebar,
            let contentViewController = window.contentViewController
        else {
            return
        }

        let storyboard = NSStoryboard(name: "OutlineSidebarView", bundle: Bundle(for: OutlineSidebarViewController.self))
        if let viewController = storyboard.instantiateController(withIdentifier: "Search Editor View Controller") as? OutlineSidebarSearchEditorViewController {
            viewController.creatingNew = true
            viewController.completionCallback = { (label, search, embedded) -> Void in
                outlineSidebar.createSearchItem(label, search: search, embedded: embedded, referenceItemID: ((sender as? NSMenuItem)?.representedObject as? OutlineSidebarItem)?.id)
            }
            contentViewController.presentAsSheet(viewController)
        }
    }

    @IBAction func editSearch(_ sender: Any?) {
        guard
            let window = sidebarView.window,
            let outlineEditor = outlineEditor,
            let outlineSidebar = outlineEditor.outlineSidebar,
            let contentViewController = window.contentViewController,
            let sidebarItem = searchItemForSender(sender)
        else {
            return
        }

        let storyboard = NSStoryboard(name: "OutlineSidebarView", bundle: Bundle(for: OutlineSidebarViewController.self))
        if let viewController = storyboard.instantiateController(withIdentifier: "Search Editor View Controller") as? OutlineSidebarSearchEditorViewController {
            let searchItem = outlineSidebar.searchItemForID(sidebarItem.id)
            viewController.creatingNew = false
            viewController.label = searchItem.bodyContent
            viewController.search = searchItem.attributeForName("data-search") ?? ""
            viewController.embedded = searchItem.jsOutline == outlineEditor.outline.jsOutline
            viewController.completionCallback = { (label, search, embedded) -> Void in
                outlineSidebar.updateSearchItem(sidebarItem.id, label: label, search: search, embedded: embedded)
            }
            contentViewController.presentAsSheet(viewController)
        }
    }

    @IBAction func deleteSearch(_ sender: Any?) {
        guard
            let window = sidebarView.window,
            let outlineEditor = outlineEditor,
            let outlineSidebar = outlineEditor.outlineSidebar,
            let sidebarItem = searchItemForSender(sender)
        else {
            return
        }

        let searchItem = outlineSidebar.searchItemForID(sidebarItem.id)
        let embedded = searchItem.jsOutline == outlineEditor.outline.jsOutline

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Delete this search?", tableName: "SavedSearchSheet", comment: "message text")
        if embedded {
            alert.informativeText = NSLocalizedString("This action can be undone.", tableName: "SavedSearchSheet", comment: "informative text")
        } else {
            alert.informativeText = NSLocalizedString("This action cannot be undone.", tableName: "SavedSearchSheet", comment: "informative text")
        }

        alert.addButton(withTitle: NSLocalizedString("OK", tableName: "SavedSearchSheet", comment: "button"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", tableName: "SavedSearchSheet", comment: "button"))
        alert.beginSheetModal(for: window, completionHandler: { response in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                searchItem.removeFromParent()
            }
        })
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let newSearch = NSMenuItem(title: NSLocalizedString("New Search", tableName: "Sidebar", comment: "menu"), action: #selector(newSearch(_:)), keyEquivalent: "")
        let editSearch = NSMenuItem(title: NSLocalizedString("Edit Search", tableName: "Sidebar", comment: "menu"), action: #selector(editSearch(_:)), keyEquivalent: "")
        let deleteSearch = NSMenuItem(title: NSLocalizedString("Delete Search", tableName: "Sidebar", comment: "menu"), action: #selector(deleteSearch(_:)), keyEquivalent: "")

        if let clickedItem = sidebarView.item(atRow: sidebarView.clickedRow) as? OutlineSidebarItem {
            func addOpenInItems() {
                menu.addItem(withTitle: NSLocalizedString("Open in New Window", tableName: "Sidebar", comment: "menu"), action: #selector(openInNewWindow(_:)), keyEquivalent: "")
                menu.addItem(withTitle: NSLocalizedString("Open in New Tab", tableName: "Sidebar", comment: "menu"), action: #selector(openInNewTab(_:)), keyEquivalent: "")
                menu.addItem(NSMenuItem.separator())
            }

            switch clickedItem.id {
            default:
                switch clickedItem.type {
                case "home":
                    addOpenInItems()
                case "project":
                    addOpenInItems()
                    menu.addItem(NSMenuItem.separator())
                case "search":
                    addOpenInItems()
                    menu.addItem(NSMenuItem.separator())
                    menu.addItem(newSearch.copy() as! NSMenuItem)
                    menu.addItem(editSearch.copy() as! NSMenuItem)
                    menu.addItem(NSMenuItem.separator())
                    menu.addItem(deleteSearch.copy() as! NSMenuItem)
                case "tag":
                    addOpenInItems()
                default:
                    switch clickedItem.id {
                    case "searches":
                        menu.addItem(newSearch.copy() as! NSMenuItem)
                    default:
                        break
                    }
                }
            }

            for each in menu.items {
                each.representedObject = clickedItem
            }
        }
    }
}
