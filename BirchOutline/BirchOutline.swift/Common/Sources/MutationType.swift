//
//  MutationType.swift
//  BirchOutline
//
//  Created by Jesse Grosjean on 7/23/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation
import JavaScriptCore

public enum MutationKind {
    
    case attribute
    case body
    case children

}

public protocol MutationType: AnyObject {
    
    var target: ItemType { get }
    var type: MutationKind { get }
    var addedItems: [ItemType]? { get }
    var removedItems: [ItemType]? { get }
    var previousSibling: ItemType? { get }
    var nextSibling: ItemType? { get }
    
}

open class Mutation: MutationType {
    
    open var jsMutation: JSValue
    
    init(jsMutation: JSValue) {
        self.jsMutation = jsMutation
    }
    
    open var target: ItemType {
        return jsMutation.forProperty("target")
    }
    
    open var type: MutationKind {
        switch jsMutation.forProperty("type").toString() {
        case "attribute":
            return .attribute
        case "body":
            return .body
        case "children":
            return .children
        default:
            assert(false, "Unexpected mutation type string")
            return .attribute // swift compiler error otherwise
        }
    }
    
    open var addedItems: [ItemType]? {
        if let addedItems = jsMutation.forProperty("addedItems").selfOrNil() {
            return addedItems.toItemTypeArray()
        }
        return nil
    }
    
    open var removedItems: [ItemType]? {
        if let removedItems = jsMutation.forProperty("removedItems").selfOrNil() {
            return removedItems.toItemTypeArray()
        }
        return nil
    }

    open var previousSibling: ItemType? {
        return jsMutation.forProperty("previousSibling").selfOrNil()
    }

    open var nextSibling: ItemType? {
        return jsMutation.forProperty("nextSibling").selfOrNil()
    }

}
