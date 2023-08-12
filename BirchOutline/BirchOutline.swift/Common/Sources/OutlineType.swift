//
//  OutlineType.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation
import JavaScriptCore

public protocol OutlineType: AnyObject {
    
    var jsOutline: JSValue { get }
    
    var root: ItemType { get }
    var items: [ItemType] { get }
    
    func itemForID(_ id: String) -> ItemType?
    func evaluateItemPath(_ path: String) -> [ItemType]
    
    func createItem(_ text: String) -> ItemType
    func cloneItem(_ item: ItemType, deep: Bool) -> ItemType
    func cloneItems(_ items: [ItemType], deep: Bool) -> [ItemType]
    
    func beginUndoGrouping()
    func endUndoGrouping()
    func groupUndo(_ callback: @escaping () -> Void)
    func groupChanges(_ callback: @escaping () -> Void)
    
    var changed: Bool { get }
    func beginChanges()
    func endChanges()
    func updateChangeCount(_ changeKind: ChangeKind)
    func onDidUpdateChangeCount(_ callback: @escaping (_ changeKind: ChangeKind) -> Void) -> DisposableType
    func onWillChange(_ callback: @escaping () -> Void) -> DisposableType
    func onDidChange(_ callback: @escaping (_ mutation: MutationType) -> Void) -> DisposableType
    func onDidEndChanges(_ callback: @escaping (_ mutations: [MutationType]) -> Void) -> DisposableType
    func onWillReload(_ callback: @escaping () -> Void) -> DisposableType
    func onDidReload(_ callback: @escaping () -> Void) -> DisposableType

    func undo()
    func redo()
    func breakUndoCoalescing()
    
    var serializedMetadata: String { get set }
    
    func serializeItems(_ items: [ItemType], options: [String : Any]?) -> String
    func deserializeItems(_ serializedItems: String, options: [String : Any]?) -> [ItemType]?
    func serialize(_ options: [String: Any]?) -> String
    func reloadSerialization(_ serialization: String, options: [String: Any]?)

    var retainCount: Int { get }
}

public enum ChangeKind {

    case done
    case undone
    case redone
    case cleared

    public init?(string: String) {
        switch string {
        case "Done":
            self = .done
        case "Undone":
            self = .undone
        case "Redone":
            self = .redone
        case "Cleared":
            self = .cleared
        default:
            return nil
        }
    }
    
    public func toString() -> String {
        switch self {
        case .done:
            return "Done"
        case .undone:
            return "Undone"
        case .redone:
            return "Redone"
        case .cleared:
            return "Cleared"
        }
    }

}

public class Outline: OutlineType {
    
    public var jsOutline: JSValue
    
    public init(jsOutline: JSValue) {
        self.jsOutline = jsOutline
    }

    public var root: ItemType {
        return jsOutline.forProperty("root")
    }
    
    public var items: [ItemType] {
        return jsOutline.forProperty("items").toItemTypeArray()
    }
    
    public func itemForID(_ id: String) -> ItemType? {
        return jsOutline.invokeMethod("getItemForID", withArguments: [id]).selfOrNil()
    }
    
    public func evaluateItemPath(_ path: String) -> [ItemType] {
        return jsOutline.invokeMethod("evaluateItemPath", withArguments: [path]).toItemTypeArray()
    }
    
    public func createItem(_ text: String) -> ItemType {
        return jsOutline.invokeMethod("createItem", withArguments: [text])
    }
    
    public func cloneItem(_ item: ItemType, deep: Bool = true) -> ItemType {
        return jsOutline.invokeMethod("cloneItem", withArguments: [item, deep])
    }
    
    public func cloneItems(_ items: [ItemType], deep: Bool = true) -> [ItemType] {
        let jsItems = JSValue.fromItemTypeArray(items, context: jsOutline.context)
        let jsItemsClone = jsOutline.invokeMethod("cloneItems", withArguments: [jsItems, deep])
        return jsItemsClone!.toItemTypeArray()
    }

    public func beginUndoGrouping() {
        jsOutline.invokeMethod("beginUndoGrouping", withArguments: [])
    }
    
    public func endUndoGrouping() {
        jsOutline.invokeMethod("endUndoGrouping", withArguments: [])
    }
    
    public func beginChanges() {
        jsOutline.invokeMethod("beginChanges", withArguments: [])
    }
    
    public func endChanges() {
        jsOutline.invokeMethod("endChanges", withArguments: [])
    }

    public func groupUndo(_ callback: @escaping () -> Void) {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        jsOutline.invokeMethod("groupUndo", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    public func groupChanges(_ callback: @escaping () -> Void) {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        jsOutline.invokeMethod("groupChanges", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }
    
    public var changed: Bool {
        return jsOutline.forProperty("isChanged").toBool()
    }
    
    public func updateChangeCount(_ changeKind: ChangeKind) {
        jsOutline.invokeMethod("updateChangeCount", withArguments: [changeKind.toString()])
    }
    
    public func onDidUpdateChangeCount(_ callback: @escaping (_ changeKind: ChangeKind) -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) (_ changeKindString: String) -> Void = { changeKindString in
            callback(ChangeKind(string: changeKindString)!)
        }
        return jsOutline.invokeMethod("onDidUpdateChangeCount", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }
    
    public func onWillChange(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsOutline.invokeMethod("onWillChange", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    public func onDidChange(_ callback: @escaping (_ mutation: MutationType) -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) (_ mutation: JSValue) -> Void = { mutation in
            callback(Mutation(jsMutation: mutation))
        }
        return jsOutline.invokeMethod("onDidChange", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    public func onDidEndChanges(_ callback: @escaping (_ mutations: [MutationType]) -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) (_ mutation: JSValue) -> Void = { jsMutations in
            let length = Int((jsMutations.forProperty("length").toInt32()))
            var mutations = [Mutation]()
            for i in 0..<length {
                mutations.append(Mutation(jsMutation: jsMutations.atIndex(i)))
            }
            callback(mutations)
        }
        return jsOutline.invokeMethod("onDidEndChanges", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }
    
    public func onWillReload(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsOutline.invokeMethod("onWillReload", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    public func onDidReload(_ callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsOutline.invokeMethod("onDidReload", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }
    
    public func undo() {
        jsOutline.invokeMethod("undo", withArguments: [])
    }
    
    public func redo() {
        jsOutline.invokeMethod("redo", withArguments: [])
    }

    public func breakUndoCoalescing() {
        jsOutline.invokeMethod("breakUndoCoalescing", withArguments: [])
    }

    public var serializedMetadata: String {
        get {
            return jsOutline.forProperty("serializedMetadata").toString()
        }
        set {
            jsOutline.setValue(newValue, forProperty: "serializedMetadata")
        }
    }

    public func serializeItems(_ items: [ItemType], options: [String : Any]?) -> String {
        let mapped: [Any] = items.map { $0 }
        return jsOutline.invokeMethod("serializeItems", withArguments: [mapped, options as Any]).toString()
    }

    public func deserializeItems(_ serializedItems: String, options: [String : Any]?) -> [ItemType]? {
        return jsOutline.invokeMethod("deserializeItems", withArguments: [serializedItems, options as Any])?.selfOrNil()?.toItemTypeArray()
    }
    
    public func serialize(_ options:[String: Any]?) -> String {
        return jsOutline.invokeMethod("serialize", withArguments: [options as Any]).toString()
    }
    
    public func reloadSerialization(_ serialization: String, options: [String: Any]?) {
        jsOutline.invokeMethod("reloadSerialization", withArguments: [serialization, options as Any])
    }
    
    public var retainCount: Int {
        return Int(jsOutline.forProperty("retainCount").toInt32())
    }
    
}
