//
//  JSValue.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/14/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation
import JavaScriptCore

extension JSValue {
    
    public func selfOrNil() -> JSValue? {
        if isNull || isUndefined {
            return nil
        }
        return self
    }
    
    // must be ...
    public class func fromItemTypeArray(_ items: [ItemType], context: JSContext) -> JSValue {
        let jsItems = JSValue(newArrayIn: context)
        for i in 0..<items.count {
            jsItems?.setValue(items[i], at: i)
        }
        return jsItems!
    }

    // ... a better way?
    public func toItemTypeArray() -> [ItemType] {
        let length = Int(forProperty("length").toInt32())
        var result: [ItemType] = []
        for i in 0..<length {
            if let each = atIndex(i) {
                result.append(each)
            }
        }
        return result
    }
    
}
