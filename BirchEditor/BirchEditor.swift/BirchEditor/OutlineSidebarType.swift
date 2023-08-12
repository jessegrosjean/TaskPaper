//
//  Sidebar.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/25/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Foundation
import JavaScriptCore

public protocol OutlineSidebarType: AnyObject {
    var rootItem: OutlineSidebarItem! { get }
    var homeItem: OutlineSidebarItem { get }
    var projectsGroup: OutlineSidebarItem { get }
    var searchesGroup: OutlineSidebarItem { get }
    var tagsGroup: OutlineSidebarItem { get }

    func shouldSelectItem(_ item: OutlineSidebarItem) -> Bool
    var selectedItem: OutlineSidebarItem! { get set }

    func onDidChangeSelection(_ callback: @escaping () -> Void) -> DisposableType
    func onDidChangeItems(_ callback: @escaping () -> Void) -> DisposableType

    func singleAction()
    func doubleAction()
    func reloadImmediate()

    func persistentID(forItemID: String) -> String?
    func itemIDFor(persistentID: String) -> String?

    func itemForID(_ id: String) -> OutlineSidebarItem?
    func matchItemFromIDs(_ itemIDs: [String], searchString: String) -> OutlineSidebarItem?

    func searchItemForID(_ id: String) -> ItemType
    func createSearchItem(_ label: String, search: String, embedded: Bool, referenceItemID: String?)
    func updateSearchItem(_ id: String, label: String, search: String, embedded: Bool)

    func getAutocompleteTagsForPartialTag(_ partialTagFilter: String?) -> [String]

    func destroy()
}

protocol OutlineSidebarItemFactoryType: AnyObject {
    func vendOutlineSidebarItem(_ jsOutlineSidebarItem: JSValue) -> OutlineSidebarItem
}

final class OutlineSidebar: NSObject, OutlineSidebarType, OutlineSidebarItemFactoryType {
    weak var outlineEditor: OutlineEditor?

    var jsOutlineSidebar: JSValue
    var rootItem: OutlineSidebarItem!
    var idsToOutlineSidebarItems = [String: OutlineSidebarItem]()

    init(outlineEditor: OutlineEditor, scriptContext: BirchScriptContext) {
        jsOutlineSidebar = scriptContext.jsOutlineSidebarClass.construct(withArguments: [outlineEditor.jsOutlineEditor as Any])
        super.init()
        self.outlineEditor = outlineEditor
        rootItem = vendOutlineSidebarItem(jsOutlineSidebar.forProperty("rootItem"))
    }

    var homeItem: OutlineSidebarItem {
        return idsToOutlineSidebarItems[jsOutlineSidebar.forProperty("homeItem").forProperty("id").toString()]!
    }

    var projectsGroup: OutlineSidebarItem {
        return idsToOutlineSidebarItems[jsOutlineSidebar.forProperty("projectsGroup").forProperty("id").toString()]!
    }

    var searchesGroup: OutlineSidebarItem {
        return idsToOutlineSidebarItems[jsOutlineSidebar.forProperty("searchesGroup").forProperty("id").toString()]!
    }

    var tagsGroup: OutlineSidebarItem {
        return idsToOutlineSidebarItems[jsOutlineSidebar.forProperty("tagsGroup").forProperty("id").toString()]!
    }

    func shouldSelectItem(_ item: OutlineSidebarItem) -> Bool {
        return jsOutlineSidebar.invokeMethod("shouldSelectItem", withArguments: [item]).toBool()
    }

    var selectedItem: OutlineSidebarItem! {
        get {
            let id = jsOutlineSidebar.forProperty("selectedItem").forProperty("id").toString()
            return idsToOutlineSidebarItems[id!]!
        }

        set(value) {
            jsOutlineSidebar.setValue(value.id, forProperty: "selectedItem")
        }
    }

    func vendOutlineSidebarItem(_ jsOutlineSidebarItem: JSValue) -> OutlineSidebarItem {
        let id = jsOutlineSidebarItem.forProperty("id").toString()
        if let item = idsToOutlineSidebarItems[id!] {
            item.reInitBranch(jsOutlineSidebarItem, factory: self)
            return item
        } else {
            let item = OutlineSidebarItem(jsOutlineSidebarItem: jsOutlineSidebarItem, factory: self)
            idsToOutlineSidebarItems[item.id] = item
            return item
        }
    }

    func onDidChangeSelection(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsOutlineSidebar.invokeMethod("onDidChangeSelection", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    func onDidChangeItems(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = { [weak self] in
            if let strongSelf = self {
                strongSelf.rootItem = strongSelf.vendOutlineSidebarItem(strongSelf.jsOutlineSidebar.forProperty("rootItem"))
            }
            callback()
        }

        return jsOutlineSidebar.invokeMethod("onDidChangeItems", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    func singleAction() {
        jsOutlineSidebar.invokeMethod("singleAction", withArguments: [])
    }

    func doubleAction() {
        jsOutlineSidebar.invokeMethod("doubleAction", withArguments: [])
    }

    func reloadImmediate() {
        jsOutlineSidebar.invokeMethod("reloadImmediate", withArguments: [])
    }

    func persistentID(forItemID: String) -> String? {
        return jsOutlineSidebar.invokeMethod("persistentIDForItemID", withArguments: [forItemID])?.selfOrNil()?.toString()
    }

    func itemIDFor(persistentID: String) -> String? {
        if let id = jsOutlineSidebar.invokeMethod("itemIDForPersistentID", withArguments: [persistentID])?.selfOrNil()?.toString() {
            return id
        }
        return nil
    }

    func itemForID(_ id: String) -> OutlineSidebarItem? {
        return idsToOutlineSidebarItems[id]
    }

    func matchItemFromIDs(_ itemIDs: [String], searchString: String) -> OutlineSidebarItem? {
        if let jsItem = jsOutlineSidebar.invokeMethod("matchItemFromIDs", withArguments: [itemIDs, searchString]).selfOrNil() {
            return idsToOutlineSidebarItems[jsItem.forProperty("id").toString()]
        }
        return nil
    }

    func searchItemForID(_ id: String) -> ItemType {
        return jsOutlineSidebar.invokeMethod("searchItemForID", withArguments: [id])
    }

    func createSearchItem(_ label: String, search: String, embedded: Bool, referenceItemID: String? = "") {
        jsOutlineSidebar.invokeMethod("createSearchItem", withArguments: [label, search, embedded, referenceItemID ?? ""])
    }

    func updateSearchItem(_ id: String, label: String, search: String, embedded: Bool) {
        jsOutlineSidebar.invokeMethod("updateSearchItem", withArguments: [id, label, search, embedded])
    }

    public func getTagAttributeNames() -> [String] {
        var tags = [String]()
        for each in tagsGroup.children {
            tags.append(each.title)
        }
        return tags
    }

    public func getAutocompleteTagsForPartialTag(_ partialTagFilter: String?) -> [String] {
        let trimmedTags = getTagAttributeNames()
        if let partialTagFilter = partialTagFilter {
            return trimmedTags.filter { each in
                if each.hasPrefix(partialTagFilter) {
                    if each == partialTagFilter {
                        if let outline = outlineEditor?.outline {
                            return outline.evaluateItemPath(partialTagFilter).count > 1
                        }
                    }
                    return true
                }
                return false
            }
        } else {
            return trimmedTags
        }
    }

    func destroy() {
        jsOutlineSidebar.invokeMethod("destroy", withArguments: [])
    }
}
