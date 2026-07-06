//
//  JavaScriptContext.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/31/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import JavaScriptCore
import WebKit

@MainActor
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
    context.exceptionHandler = { _, exception in
        let message = NSLocalizedString("Uncaught JavaScript Exception", tableName: "JavascriptException", comment: "message text")
        let description = exception?.toString() ?? "Unknown exception"
        let stack = exception?.forProperty("stack")?.toString() ?? "No stack trace"
        let informativeText = NSLocalizedString("\(description)\n\n\(stack)", tableName: "JavascriptException", comment: "informative text")
        cpAlert(message, informativeText: informativeText)
        exit(EXIT_FAILURE)
    }
}

// JS timers are main-actor state: JS only ever evaluates on the main thread,
// and the fired callbacks re-enter the JS context.
@MainActor
private final class TimeoutRegistry {
    var nextID: Int32 = 1
    var callbacks = [Int32: JSValue]()
}

@MainActor
func setTimeoutAndClearTimeoutHandlers(_ context: JSContext) {
    installTimeoutHandlers(context, registry: TimeoutRegistry())
}

// Nonisolated so the blocks below stay nonisolated function values (a closure
// formed in a @MainActor context would infer @MainActor isolation, which is
// ill-formed for a block taking non-Sendable JSValue parameters).
private func installTimeoutHandlers(_ context: JSContext, registry: TimeoutRegistry) {
    // JSC invokes these blocks on whatever thread evaluates JS — always the
    // main thread in this app. assumeIsolated documents and enforces that
    // invariant at runtime rather than assuming it silently.
    let setTimeout: @convention(block) (JSValue, Int) -> JSValue = { (callback, wait) in
        // The block runs on the main thread (asserted below), so the JSValue
        // parameter never actually crosses an isolation boundary.
        nonisolated(unsafe) let callback = callback
        // assumeIsolated can only return Sendable values, so hand back the
        // timer ID and build the JSValue outside.
        let thisTimeOutID: Int32 = MainActor.assumeIsolated {
            let thisTimeOutID = registry.nextID
            registry.nextID += 1
            registry.callbacks[thisTimeOutID] = callback
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(UInt64(wait) * NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)) {
                MainActor.assumeIsolated {
                    let _ = registry.callbacks.removeValue(forKey: thisTimeOutID)?.call(withArguments: [])
                }
            }
            return thisTimeOutID
        }
        return JSValue.init(int32: thisTimeOutID, in: context)
    }

    let clearTimeout: @convention(block) (JSValue) -> Void = { (timeoutID) in
        // The block runs on the main thread (asserted below), so the JSValue
        // parameter never actually crosses an isolation boundary.
        nonisolated(unsafe) let timeoutID = timeoutID
        MainActor.assumeIsolated {
            _ = registry.callbacks.removeValue(forKey: timeoutID.toInt32())
        }
    }

    context.setObject(unsafeBitCast(setTimeout, to: AnyObject.self), forKeyedSubscript: "setTimeout" as (NSCopying & NSObjectProtocol))
    context.setObject(unsafeBitCast(clearTimeout, to: AnyObject.self), forKeyedSubscript: "clearTimeout" as (NSCopying & NSObjectProtocol))
}
