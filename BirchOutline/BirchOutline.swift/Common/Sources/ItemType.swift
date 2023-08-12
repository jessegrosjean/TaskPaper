//
//  ItemType.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation
import JavaScriptCore

public protocol ItemType: AnyObject {
    
    static func getCommonAncestors(_ items: [ItemType]) -> [ItemType]
    
    var jsOutline: JSValue { get }
    var id: String { get }
    var parent: ItemType? { get }
    var firstChild: ItemType? { get }
    var lastChild: ItemType? { get }
    var previousSibling: ItemType? { get }
    var nextSibling: ItemType? { get }
    var children: [ItemType] { get }
    var descendants: [ItemType] { get }

    func contains(_ item: ItemType) -> Bool

    func insertChildren(_ children: [ItemType], beforeSibling: ItemType?)
    func appendChildren(_ children: [ItemType])
    func removeChildren(_ children: [ItemType])
    func removeFromParent()

    var attributes: [String:String] { get }
    func hasAttribute(_ name: String) -> Bool
    func attributeForName(_ name: String) -> String?
    func attributeForName(_ name: String, className: String) -> Any?
    func setAttribute(_ name: String, value: Any)
    func removeAttribute(_ name: String)
    
    var body: String { get set }
    var bodyContent: String { get set }
    
}

extension JSValue: ItemType {

    public static func getCommonAncestors(_ items: [ItemType]) -> [ItemType] {
        return BirchOutline.sharedContext.jsItemClass.invokeMethod("getCommonAncestors", withArguments: [items]).toItemTypeArray()
    }

    public var jsOutline: JSValue {
        return forProperty("outline")
    }

    public var id: String {
        return forProperty("id").toString()
    }

    public var parent: ItemType? {
        return forProperty("parent").selfOrNil()
    }

    public var firstChild: ItemType? {
        return forProperty("firstChild").selfOrNil()
    }

    public var lastChild: ItemType? {
        return forProperty("lastChild").selfOrNil()
    }

    public var previousSibling: ItemType? {
        return forProperty("previousSibling").selfOrNil()
    }

    public var nextSibling: ItemType? {
        return forProperty("nextSibling").selfOrNil()
    }
    
    public var children: [ItemType] {
        return forProperty("children").toItemTypeArray() 
    }

    public var descendants: [ItemType] {
        return forProperty("descendants").toItemTypeArray()
    }
    
    public func contains(_ item: ItemType) -> Bool {
        return invokeMethod("contains", withArguments: [item]).toBool()
    }

    public func insertChildren(_ children: [ItemType], beforeSibling: ItemType?) {
        let mapped: [Any] = children.map { $0 }
        if let beforeSibling = beforeSibling {
            invokeMethod("insertChildrenBefore", withArguments: [mapped, beforeSibling])
        } else {
            invokeMethod("insertChildrenBefore", withArguments: [mapped])
        }
    }

    public func appendChildren(_ children: [ItemType]) {
        let mapped: [Any] = children.map { $0 }
        invokeMethod("appendChildren", withArguments: [mapped])
    }
    
    public func removeChildren(_ children: [ItemType]) {
        let mapped: [Any] = children.map { $0 }
        invokeMethod("removeChildren", withArguments: [mapped])
    }
    
    public func removeFromParent() {
       invokeMethod("removeFromParent", withArguments: [])
    }
    
    public var attributes: [String:String] {
        return forProperty("attributes").toDictionary() as? [String:String] ?? [:]
    }
    
    public func hasAttribute(_ name: String) -> Bool {
        return invokeMethod("hasAttribute", withArguments: [name]).toBool()
    }
    
    public func attributeForName(_ name: String) -> String? {
        return invokeMethod("getAttribute", withArguments: [name]).selfOrNil()?.toString()
    }

    public func attributeForName(_ name: String, className: String) -> Any? {
        return invokeMethod("getAttribute", withArguments: [name, className]).selfOrNil()?.toObject()
    }

    public func setAttribute(_ name: String, value: Any) {
        invokeMethod("setAttribute", withArguments: [name, value])
    }
    
    public func removeAttribute(_ name: String) {
        invokeMethod("removeAttribute", withArguments: [name])
    }

    public var body: String {
        get {
            return forProperty("bodyString").toString()
        }
        set (value) {
            setValue(value, forProperty: "bodyString")
        }
    }
    
    public var bodyContent: String {
        get {
            return forProperty("bodyContentString").toString()
        }
        set (value) {
            return setValue(value, forProperty: "bodyContentString")
        }
    }
    
}
