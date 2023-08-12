//
//  Commands.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/18/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline

class ScriptCommands: NSObject {
    static var scriptCommandsDisposables: [DisposableType]?
    static var scriptsFolderMonitor: PathMonitor?

    static func initScriptCommands() {
        let fileManager = FileManager.default
        if let scriptsURL = try? fileManager.URLForApplicationsScriptsDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true) {
            scriptsFolderMonitor = PathMonitor(URL: scriptsURL, callback: {
                self.reloadScriptCommands()
            })
            scriptsFolderMonitor?.startDirectoryMonitoring()
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
            let scriptsPath = scriptsURL.path
            if let directoryContents = try? fileManager.contentsOfDirectory(atPath: scriptsPath) {
                for eachFile in directoryContents {
                    let eachURL = scriptsURL.appendingPathComponent(eachFile)
                    if let _ = try? NSUserScriptTask(url: eachURL) {
                        scriptCommandsDisposables?.append(Commands.add("outlineEditor", commandName: "User Script: \(eachFile.stringByDeletingPathExtension)", callback: {
                            if let runScript = try? NSUserScriptTask(url: eachURL) {
                                runScript.execute { error in
                                    if let error = error {
                                        DispatchQueue.main.async {
                                            NSApp.presentError(error)
                                        }
                                    }
                                }
                            }
                        }))
                    }
                }
            }
        }
    }
}
