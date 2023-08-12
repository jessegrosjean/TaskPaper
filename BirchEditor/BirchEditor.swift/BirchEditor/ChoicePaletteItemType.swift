//
//  MenuItemType.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import JavaScriptCore

@objc public protocol ChoicePaletteItemType: JSExport {
    weak var parent: ChoicePaletteItemType? { get set }
    var children: [ChoicePaletteItemType] { get }
    var ancestors: [ChoicePaletteItemType] { get }
    var descendents: [ChoicePaletteItemType] { get }

    var type: String { get }
    var title: String { get }
    var titleMatchIndexes: JSValue? { get set }
    var indentationLevel: Int { get }
    var representedObject: Any? { get }

    var isGroup: Bool { get }
    var isSelectable: Bool { get }

    func cloneItem() -> ChoicePaletteItemType
    func cloneBranch() -> ChoicePaletteItemType
    func appendChild(_ child: ChoicePaletteItemType)
}

open class ChoicePaletteItem: NSObject, ChoicePaletteItemType {
    open var type: String
    open var title: String
    open var titleMatchIndexes: JSValue?
    open var representedObject: Any?
    open weak var parent: ChoicePaletteItemType?
    open var children: [ChoicePaletteItemType]

    open var isGroup: Bool {
        return type == "group"
    }

    open var isSelectable: Bool {
        return !(type == "group" || type == "label")
    }

    init(type: String, title: String) {
        self.type = type
        self.title = title
        children = []
    }

    open var ancestors: [ChoicePaletteItemType] {
        var ancestors = [ChoicePaletteItemType]()
        var eachParent = parent
        while let each = eachParent {
            ancestors.append(each)
            eachParent = each.parent
        }
        return ancestors
    }

    open var ancestorsWithSelf: [ChoicePaletteItemType] {
        var result = ancestors
        result.insert(self, at: 0)
        return result
    }

    open var descendents: [ChoicePaletteItemType] {
        var descendants = [ChoicePaletteItemType]()
        func visit(_ item: ChoicePaletteItemType) {
            for each in item.children {
                descendants.append(each)
                visit(each)
            }
        }
        visit(self)
        return descendants
    }

    open var indentationLevel: Int {
        var level = 0
        var each = parent
        while each != nil {
            level += 1
            each = each?.parent
        }
        return level
    }

    open func appendChild(_ child: ChoicePaletteItemType) {
        child.parent = self
        children.append(child)
    }

    open func cloneBranch() -> ChoicePaletteItemType {
        func recursiveCloneItem(_ item: ChoicePaletteItemType) -> ChoicePaletteItemType {
            let clone = item.cloneItem()
            for each in item.children {
                clone.appendChild(recursiveCloneItem(each))
            }
            return clone
        }
        return recursiveCloneItem(self)
    }

    open func cloneItem() -> ChoicePaletteItemType {
        let clone = ChoicePaletteItem(type: type, title: title)
        clone.representedObject = representedObject
        return clone
    }
}

func flattenChoicePaletteItemBranches(_ choicePaletteItems: [ChoicePaletteItemType]) -> [ChoicePaletteItemType] {
    var flat = [ChoicePaletteItemType]()
    for each in choicePaletteItems {
        flat.append(each)
        for eachDescendant in each.descendents {
            flat.append(eachDescendant)
        }
    }
    return flat
}
