//
//  OutlineItemOutlineSidebarItem.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/27/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa
import JavaScriptCore

open class OutlineSidebarItem: ChoicePaletteItem {
    let id: String

    var attributesHash: UInt32 = 0
    var childrenHash: UInt32 = 0
    var branchHash: UInt32 = 0

    var attributesChanged = false
    var childrenChanged = false
    var branchChanged = false
    var becameParent = false

    init(id: String, type: String, title: String) {
        self.id = id
        super.init(type: type, title: title)
    }

    init(jsOutlineSidebarItem: JSValue, factory: OutlineSidebarItemFactoryType) {
        id = jsOutlineSidebarItem.forProperty("id").toString()

        super.init(type: jsOutlineSidebarItem.forProperty("type").toString(), title: jsOutlineSidebarItem.forProperty("title").toString())

        reInitBranch(jsOutlineSidebarItem, factory: factory)

        becameParent = false
    }

    func reInitBranch(_ jsOutlineSidebarItem: JSValue, factory: OutlineSidebarItemFactoryType) {
        let hadChildren = children.count > 0

        parent = nil
        attributesChanged = false
        childrenChanged = false
        branchChanged = false

        let newAttributesHash = jsOutlineSidebarItem.forProperty("attributesHash").toUInt32()
        if newAttributesHash != attributesHash {
            attributesHash = newAttributesHash
            title = jsOutlineSidebarItem.forProperty("title").toString()
            representedObject = jsOutlineSidebarItem.forProperty("representedObject").selfOrNil()?.toObject()
            attributesChanged = true
        }

        let newChildrenHash = jsOutlineSidebarItem.forProperty("childrenHash").toUInt32()
        if newChildrenHash != childrenHash {
            childrenHash = newChildrenHash
            childrenChanged = true
        }

        let newBranchHash = jsOutlineSidebarItem.forProperty("branchHash").toUInt32()
        if newBranchHash != branchHash {
            branchHash = newBranchHash
            branchChanged = true
            children = []

            if let jsChildren = jsOutlineSidebarItem.forProperty("children") {
                let length = Int(jsChildren.forProperty("length").toInt32())
                for i in 0 ..< length {
                    let eachChild = factory.vendOutlineSidebarItem(jsChildren.atIndex(i))
                    children.append(eachChild)
                    eachChild.parent = self
                }
            }
        }

        becameParent = !hadChildren && children.count > 0
    }

    override open func cloneItem() -> ChoicePaletteItemType {
        let clone = OutlineSidebarItem(id: id, type: type, title: title)
        clone.representedObject = representedObject
        return clone
    }
}
