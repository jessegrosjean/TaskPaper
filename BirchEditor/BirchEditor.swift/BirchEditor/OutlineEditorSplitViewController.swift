//
//  OutlineViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/26/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

let BUserFontSizeDefaultsKey = "BUserFontSizeDefaultsKey"
let BUserFontDefaultSize = 14

open class OutlineEditorSplitViewController: NSSplitViewController, /* TitleLayoutLocator, */ OutlineEditorHolderType, StylesheetHolder {
    @IBOutlet var sidebarSplitViewItem: NSSplitViewItem!
    @IBOutlet var outlineEditorSplitViewItem: NSSplitViewItem!

    open var outlineEditor: OutlineEditorType? {
        didSet {
            if
                let outlineEditor = outlineEditor,
                let outlineEditorWindowController = view.window?.windowController as? OutlineEditorWindowController,
                let serializedRestorableState = outlineEditorWindowController.outlineEditorSerializedRestorableState {
                outlineEditor.serializedRestorableState = serializedRestorableState
            }
        }
    }

    deinit {
        // Manually to force deinit immediatly. Otherwise won't release split view controllers until a few seconds after.
        for each in splitViewItems {
            removeSplitViewItem(each)
            each.viewController.view.removeFromSuperview()
        }
    }

    open var styleSheet: StyleSheet? {
        didSet {
            // view.window?.updateTitleLayout(self)
        }
    }

    var sidebarViewController: OutlineSidebarViewController {
        return sidebarSplitViewItem.viewController as! OutlineSidebarViewController
    }

    var outlineEditorViewController: OutlineEditorViewController {
        return outlineEditorSplitViewItem.viewController as! OutlineEditorViewController
    }

    // MARK: - Restorable State

    override open func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        if let serializedRestorableState = outlineEditor?.serializedRestorableState {
            coder.encode(serializedRestorableState, forKey: "serializedRestorableState")
        }
    }

    override open func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        if let serializedRestorableState = coder.decodeObject(forKey: "serializedRestorableState") as? String {
            outlineEditor?.serializedRestorableState = serializedRestorableState
        }
    }

    // MARK: - View Events

    override open func viewDidLoad() {
        super.viewDidLoad()
        splitView.autosaveName = "OutlineEditorSplitView"
        outlineEditorSplitViewItem.minimumThickness = 300
        if #available(OSX 11.0, *) {
            //outlineEditorSplitViewItem.titlebarSeparatorStyle = .none
        }

        minimumThicknessForInlineSidebars = sidebarSplitViewItem.minimumThickness + outlineEditorSplitViewItem.minimumThickness + 2

        let searchField = searchBarViewController?.searchField
        let outlineEditorView = outlineEditorViewController.outlineEditorView
        let sidebarView = sidebarViewController.sidebarView

        searchField?.nextKeyView = outlineEditorView
        outlineEditorView?.nextKeyView = sidebarView
        sidebarView?.nextKeyView = searchField
    }

    override open func viewWillAppear() {
        view.window?.initialFirstResponder = outlineEditorViewController.outlineEditorView // hack, but don't know how else to set
    }

    override open func viewDidAppear() {
        // view.window?.updateTitleLayout(self)
    }

    override open func viewWillDisappear() {
        // view.window?.updateTitleLayout(nil)
    }

    // MARK: - Actions

    @IBAction func undo(_: Any?) {
        outlineEditor?.performCommand("outline-editor:undo", options: nil)
    }

    @IBAction func redo(_: Any?) {
        outlineEditor?.performCommand("outline-editor:redo", options: nil)
    }

    @IBAction func insertDate(_: NSMenuItem?) {
        outlineEditor?.performCommand("outline-editor:insert-date", options: nil)
    }

    var searchBarViewController: SearchBarViewController? {
        return descendentViewControllers.filter { $0 is SearchBarViewController }[0] as? SearchBarViewController
    }

    @IBAction func goHome(_: Any?) {
        if let outlineEditor = outlineEditor {
            outlineEditor.hoistedItem = outlineEditor.outline.root
        }
    }

    @IBAction func beginSearch(_ sender: Any?) {
        searchBarViewController?.beginSearch(sender)
    }

    @IBAction func refreshSearch(_: Any?) {
        outlineEditor?.performCommand("outline-editor:refresh-search", options: nil)
    }

    @IBAction func closeSearch(_ sender: Any?) {
        searchBarViewController?.closeSearch(sender)
    }

    @IBAction func performFindPanelAction(_ sender: Any?) {
        if let editorView = outlineEditorViewController.outlineEditorView {
            editorView.window?.makeFirstResponder(editorView)
            editorView.performFindPanelAction(sender)
        }
    }

    @IBAction override open func centerSelectionInVisibleArea(_ sender: Any?) {
        if let editorView = outlineEditorViewController.outlineEditorView {
            editorView.window?.makeFirstResponder(editorView)
            editorView.centerSelectionInVisibleArea(sender)
        }
    }

    @IBAction open func showCommandsPalette(_: Any?) {
        var choices = [ChoicePaletteItem]()
        var namesToGroups = [String: ChoicePaletteItem]()

        func groupPaletteItem(_ name: String) -> ChoicePaletteItem {
            if let groupItem = namesToGroups[name] {
                return groupItem
            }
            let groupItem = ChoicePaletteItem(type: "group", title: name)
            namesToGroups[name] = groupItem
            choices.append(groupItem)
            return groupItem
        }

        for each in Commands.findCommands("*" as Any) {
            let components = each.displayName.components(separatedBy: ":")
            let groupName = components[0]
            let commandName = components[1].trimmingCharacters(in: CharacterSet.whitespaces)
            let groupItem = groupPaletteItem(groupName)
            let choice = ChoicePaletteItem(type: "command", title: commandName)
            choice.representedObject = each.command
            groupItem.appendChild(choice)
        }

        let placeholder = NSLocalizedString("Choose Command", tableName: "ChoicePalette", comment: "placeholder")
        ChoicePaletteWindowController.showChoicePalette(view.window, placeholder: placeholder, items: flattenChoicePaletteItemBranches(choices), completionHandler: { [weak self] _, choicePaletteItems in
            if let command = choicePaletteItems?[0].representedObject as? String {
                if let outlineEditor = self?.outlineEditor {
                    outlineEditor.performCommand(command, options: nil)
                }
            }
        })
    }

    @IBAction open func showGoToPalette(_: Any?) {
        guard let sidebar = outlineEditor?.outlineSidebar else {
            return
        }

        var choices = [sidebar.homeItem.cloneBranch()]
        choices.append(sidebar.projectsGroup.cloneBranch())
        choices.append(sidebar.searchesGroup.cloneBranch())
        choices.append(sidebar.tagsGroup.cloneBranch())

        let placeholder = NSLocalizedString("Go to Anything", tableName: "ChoicePalette", comment: "placeholder")
        ChoicePaletteWindowController.showChoicePalette(view.window, placeholder: placeholder, items: flattenChoicePaletteItemBranches(choices), completionHandler: { _, choicePaletteItems in
            if let sidebarItem = choicePaletteItems?[0] as? OutlineSidebarItem {
                sidebar.selectedItem = sidebarItem
            }
        })
    }

    @IBAction open func showProjectsPalette(_: Any?) {
        guard let sidebar = outlineEditor?.outlineSidebar else {
            return
        }

        var choices = [sidebar.homeItem.cloneBranch()]
        choices.append(sidebar.projectsGroup.cloneBranch())

        let placeholder = NSLocalizedString("Go to Project", tableName: "ChoicePalette", comment: "placeholder")
        ChoicePaletteWindowController.showChoicePalette(view.window, placeholder: placeholder, items: flattenChoicePaletteItemBranches(choices), completionHandler: { _, choicePaletteItems in
            if let sidebarItem = choicePaletteItems?[0] as? OutlineSidebarItem {
                sidebar.selectedItem = sidebarItem
            }
        })
    }

    @IBAction open func showSearchesPalette(_: Any?) {
        guard let sidebar = outlineEditor?.outlineSidebar else {
            return
        }

        var choices = [sidebar.homeItem.cloneBranch()]
        choices.append(sidebar.searchesGroup.cloneBranch())

        let placeholder = NSLocalizedString("Go to Search", tableName: "ChoicePalette", comment: "placeholder")
        ChoicePaletteWindowController.showChoicePalette(view.window, placeholder: placeholder, items: flattenChoicePaletteItemBranches(choices), completionHandler: { _, choicePaletteItems in
            if let sidebarItem = choicePaletteItems?[0] as? OutlineSidebarItem {
                sidebar.selectedItem = sidebarItem
            }
        })
    }

    @IBAction open func showTagsPalette(_: Any?) {
        guard let sidebar = outlineEditor?.outlineSidebar else {
            return
        }

        var choices = [sidebar.homeItem.cloneBranch()]
        choices.append(sidebar.tagsGroup.cloneBranch())

        let placeholder = NSLocalizedString("Go to Tag", tableName: "ChoicePalette", comment: "placeholder")
        ChoicePaletteWindowController.showChoicePalette(view.window, placeholder: placeholder, items: flattenChoicePaletteItemBranches(choices), completionHandler: { _, choicePaletteItems in
            if let sidebarItem = choicePaletteItems?[0] as? OutlineSidebarItem {
                sidebar.selectedItem = sidebarItem
            }
        })
    }

    @IBAction override open func toggleSidebar(_: Any?) {
        var sizeChange = sidebarSplitViewItem.viewController.view.frame.size.width + splitView.dividerThickness
        if sidebarSplitViewItem.isCollapsed {
            sidebarSplitViewItem.isCollapsed = false
        } else {
            sizeChange *= -1
            sidebarSplitViewItem.isCollapsed = true
        }
        if let window = view.window, !window.styleMask.contains(.fullScreen) {
            var frame = window.frame
            if !userDefaults.bool(forKey: BMaintainWindowSizeWhenTogglingSidebar) {
                frame.origin.x -= sizeChange
                frame.size.width += sizeChange
                frame = window.constrainFrameRect(frame, to: window.screen)
                window.setFrame(frame, display: true, animate: false)
            } else if !sidebarSplitViewItem.isCollapsed {
                let minSize = outlineEditorSplitViewItem.minimumThickness + sizeChange
                if frame.size.width < minSize {
                    frame.size.width = minSize
                    window.setFrame(frame, display: true, animate: false)
                }
            }
        }
    }

    @IBAction open func showSidebarAndExpandCompletely(_: Any?) {
        if sidebarSplitViewItem.isCollapsed {
            toggleSidebar(nil)
        }
        if let sidebarView = sidebarViewController.sidebarView {
            sidebarView.expandItem(nil, expandChildren: true)
        }
    }

    @IBAction func zoomToActualSize(_: Any?) {
        userDefaults.set(BUserFontDefaultSize, forKey: BUserFontSizeDefaultsKey)
    }

    @IBAction func zoomIn(_: Any?) {
        let size = userDefaults.integer(forKey: BUserFontSizeDefaultsKey)
        userDefaults.set(size + 1, forKey: BUserFontSizeDefaultsKey)
    }

    @IBAction func zoomOut(_: Any?) {
        let size = userDefaults.integer(forKey: BUserFontSizeDefaultsKey)
        if size > 8 {
            userDefaults.set(size - 1, forKey: BUserFontSizeDefaultsKey)
        }
    }

    @IBAction func newSidebarSearch(_ sender: Any?) {
        sidebarViewController.newSearch(sender)
    }

    @IBAction func editSidebarSearch(_ sender: Any?) {
        sidebarViewController.editSearch(sender)
    }

    @IBAction func deleteSidebarSearch(_ sender: Any?) {
        sidebarViewController.deleteSearch(sender)
    }

    @objc open func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if let action = menuItem.action {
            switch action {
            case #selector(editSidebarSearch(_:)):
                return sidebarViewController.searchItemForSender(menuItem) != nil
            case #selector(deleteSidebarSearch(_:)):
                return sidebarViewController.searchItemForSender(menuItem) != nil
            case #selector(toggleSidebar(_:)):
                if sidebarSplitViewItem.isCollapsed {
                    menuItem.state = .off
                } else {
                    menuItem.state = .on
                }
                return true
            default:
                return true
            }
        } else {
            return true
        }
    }

    // MARK: - Delegate

    override open func splitView(_: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt _: Int) -> CGFloat {
        return round(proposedPosition)
    }
}

// MARK: - Util

/*
 func populateProjectsMenu(menu: NSMenu, selector: Selector) {
 (sidebarSplitViewItem.viewController as? OutlineSidebarViewController)?.populateProjectsMenu(menu, selector: selector)
 }*/

// MARK: - Title Layout (abandoing this idea I think)

/*
 public func locateTitleCenter() -> CGFloat {
 if let center = view.window?.titlebarAppearsTransparent {
 if center {
 let contentView = outlineEditorSplitViewItem.viewController.view
 let frame = contentView.convertRect(contentView.bounds, toView: nil)
 let result = NSMidX(frame)
 return result
 }
 }
 return -1
 }

 public override func splitViewDidResizeSubviews(notification: Notification) {
 view.window?.updateTitleLayout(self)
 }*/
