//
//  ItemPathQueryType.swift
//  BirchOutline
//
//  Created by Jesse Grosjean on 7/24/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation
import JavaScriptCore

public protocol ItemPathQueryType: AnyObject {
    
    func onDidChange(_ callback: @escaping (_ items: [ItemType]) -> Void) -> DisposableType

    var itemPath: String { get set }
    
    var started: Bool { get }
    func start()
    func stop()
    
    var results: [ItemType] { get }
    
}

open class ItemPathQuery: ItemPathQueryType {
    
    var jsItemPathQuery: JSValue
    
    init(jsItemPathQuery: JSValue) {
        self.jsItemPathQuery = jsItemPathQuery
    }
    
    open func onDidChange(_ callback: @escaping (_ items: [ItemType]) -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) (_ items: JSValue) -> Void = { items in
            callback(items.toItemTypeArray())
        }
        return jsItemPathQuery.invokeMethod("onDidChange", withArguments: [unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }
    
    open var itemPath: String {
        get {
            return jsItemPathQuery.forProperty("itemPath").toString()
        }
        set(value) {
            return jsItemPathQuery.setValue(value, forProperty: "itemPath")
        }
    }
    
    open var started: Bool {
        return jsItemPathQuery.forProperty("started").toBool()
    }
    
    open func start() {
        jsItemPathQuery.invokeMethod("start", withArguments: [])
    }
    
    open func stop() {
        jsItemPathQuery.invokeMethod("stop", withArguments: [])
    }
    
    open var results: [ItemType] {
        return jsItemPathQuery.invokeMethod("items", withArguments: []).toItemTypeArray()
    }

}
