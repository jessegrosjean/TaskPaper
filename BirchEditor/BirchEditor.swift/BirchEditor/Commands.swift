//
//  Commands.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/18/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import JavaScriptCore

typealias Command = (command: String, displayName: String)

class Commands: NSObject {
    static let jsCommands = BirchOutline.sharedContext.jsBirchCommands
    static var scriptCommandsDisposables: [DisposableType]?
    static var scriptsFolderMonitor: PathMonitor?

    static func add(_ target: String, commandName: String, callback: @escaping () -> Void) -> DisposableType {
        let callbackWrapper: @convention(block) () -> Void = {
            callback()
        }
        return jsCommands.invokeMethod("add", withArguments: [target, commandName, unsafeBitCast(callbackWrapper, to: AnyObject.self)])
    }

    static func findCommands(_ target: Any) -> [Command] {
        var commands = [Command]()
        for each in jsCommands.invokeMethod("findCommands", withArguments: [target]).toArray() as! [NSDictionary] {
            commands.append(Command(command: each["command"] as! String, displayName: each["displayName"] as! String))
        }
        return commands
    }

    static func dispatch(_ target: Any, commandName: String, details: Any) {
        jsCommands.invokeMethod("dispatch", withArguments: [target, commandName, details])
    }

    static func initScriptCommands() {
        let fileManager = FileManager.default
        if let scriptsURL = try? fileManager.URLForApplicationsScriptsDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true) {
            scriptsFolderMonitor = PathMonitor(URL: scriptsURL, callback: {
                self.reloadScriptCommands()
            })
        }
        reloadScriptCommands()
    }

    static func reloadScriptCommands() {
        if let scriptCommandsDisposables = scriptCommandsDisposables {
            for each in scriptCommandsDisposables {
                each.dispose()
            }
        }

        scriptCommandsDisposables = [DisposableType]()

        let fileManager = FileManager.default
        if let scriptsURL = try? fileManager.URLForApplicationsScriptsDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true) {
            if let directoryContents = try? fileManager.contentsOfDirectory(atPath: scriptsURL.path) {
                for each in directoryContents {
                    scriptCommandsDisposables?.append(add("outlineEditor", commandName: each, callback: {}))
                }
            }
        }
    }
}
