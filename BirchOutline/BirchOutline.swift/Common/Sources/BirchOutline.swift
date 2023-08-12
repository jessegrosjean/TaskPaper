//
//  Birch.swift
//  Birch
//
//  Created by Jesse Grosjean on 6/10/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

open class BirchOutline {

    static var _sharedContext: BirchScriptContext!
    
    public static var sharedContext: BirchScriptContext {
        set {
            _sharedContext = newValue
        }
        get {
            if let context = _sharedContext {
                return context
            } else {
                _sharedContext = BirchScriptContext()
                return _sharedContext!
            }
        }
    }

    public static func createOutline(_ type: String?, content: String?) -> OutlineType {
        return sharedContext.createOutline(type, content: content)
    }
    
    public static func createTaskPaperOutline(_ content: String?) -> OutlineType {
        return sharedContext.createTaskPaperOutline(content)
    }

    public static func createWriteRoomOutline(_ content: String?) -> OutlineType {
        return sharedContext.createWriteRoomOutline(content)
    }

}
