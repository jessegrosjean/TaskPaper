//
//  JavaScriptContext.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/31/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import JavaScriptCore
import WebKit

open class BirchScriptContext {
    
    open var context: JSContext!    
    open var jsBirchExports: JSValue!
    
    var jsOutlineClass: JSValue {
        return jsBirchExports.forProperty("Outline")
    }

    var jsItemClass: JSValue {
        return jsBirchExports.forProperty("Item")
    }

    var jsMutationClass: JSValue {
        return jsBirchExports.forProperty("Mutation")
    }
    
    var jsItemSerializerClass: JSValue {
        return jsBirchExports.forProperty("ItemSerializer")
    }

    var jsDateTimeClass: JSValue {
        return jsBirchExports.forProperty("DateTime")
    }

    var jsItemPathClass: JSValue {
        return jsBirchExports.forProperty("ItemPath")
    }

    public init (scriptPath: String? = nil) {
        context = JSContext()
        context.name = "BirchOutlineJavaScriptContext"
        
        setExceptionHandler(context)
        setTimeoutAndClearTimeoutHandlers(context)
        
        let bundle = Bundle(for: BirchScriptContext.self)
        let path = scriptPath ?? bundle.path(forResource: "birchoutline", ofType: "js")!
        let script = try! String(contentsOfFile: path)
        let birchExportsName = path.lastPathComponent.stringByDeletingPathExtension
        
        context.evaluateScript(script, withSourceURL: URL(fileURLWithPath: path))
        
        jsBirchExports = context.objectForKeyedSubscript(birchExportsName)
    }
    
    open func createOutline(_ type: String?, content: String?) -> OutlineType {
        return Outline(jsOutline: jsOutlineClass.construct(withArguments: [type ?? "text/plain", content ?? ""]))
    }
    
    open func createTaskPaperOutline(_ content: String?) -> OutlineType {
        return Outline(jsOutline: jsOutlineClass.construct(withArguments: ["text/taskpaper", content ?? ""]))
    }

    open func createWriteRoomOutline(_ content: String?) -> OutlineType {
        return Outline(jsOutline: jsOutlineClass.construct(withArguments: ["text/writeroom", content ?? ""]))
    }

    open func garbageCollect() {
        #if os(OSX)
            context.garbageCollect()
        #endif
    }
    
}

func setExceptionHandler(_ context: JSContext) {
    context.exceptionHandler = { context, exception in
        let message = NSLocalizedString("Uncaught JavaScript Exception", tableName: "JavascriptException", comment: "message text")
        let informativeText = NSLocalizedString("\(String(describing: exception))\n\n\(String(describing: exception!.forProperty("stack")))", tableName: "JavascriptException", comment: "informative text")        
        cpAlert(message, informativeText: informativeText)
        exit(EXIT_SUCCESS)
    }
}

func setTimeoutAndClearTimeoutHandlers(_ context: JSContext) {
    var setTimeoutID: Int32 = 1
    var setTimeOutIDsToCallbacks = [Int32:JSValue]()
    
    let setTimeout: @convention(block) (JSValue, Int) -> JSValue = { (callback, wait) in
        let thisTimeOutID = setTimeoutID
        setTimeoutID += 1
        setTimeOutIDsToCallbacks[thisTimeOutID] = callback
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(wait) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC), execute: { () -> Void in
            let _ = setTimeOutIDsToCallbacks[thisTimeOutID]?.call(withArguments: [])
        })
        return JSValue.init(int32: setTimeoutID, in: context)
    }
    
    let clearTimeout: @convention(block) (JSValue) -> Void = { (timeoutID) in
        setTimeOutIDsToCallbacks.removeValue(forKey: timeoutID.toInt32())
    }

    context.setObject(unsafeBitCast(setTimeout, to: AnyObject.self), forKeyedSubscript: "setTimeout" as (NSCopying & NSObjectProtocol))
    context.setObject(unsafeBitCast(clearTimeout, to: AnyObject.self), forKeyedSubscript: "clearTimeout" as (NSCopying & NSObjectProtocol))
}
