//
//  searches.swift
//  Birch
//
//  Created by Jesse Grosjean on 9/28/16.
//
//

import BirchOutline
import Foundation

class ConfigurationOutlinesController: NSObject {
    static var outlines = [OutlineType]()
    static var subscriptions = [DisposableType]()
    static var fileMonitors = [PathMonitor]()

    static func initConfigurationOutline(_ name: String, jsOutline: JSValue) {
        let fileManager = FileManager.default

        if let applicationConfigurationURL = try? fileManager.URLForApplicationsConfigurationsDirectory(inDomain: .userDomainMask, appropriateForURL: nil, create: true) {
            let outlineURL = applicationConfigurationURL.appendingPathComponent(name)

            if !fileManager.fileExists(atPath: outlineURL.path) {
                if let bundleURL = Bundle.main.url(forResource: outlineURL.deletingPathExtension().lastPathComponent, withExtension: outlineURL.pathExtension) {
                    _ = try? fileManager.copyItem(at: bundleURL, to: outlineURL)
                }
            }

            let outline = Outline(jsOutline: jsOutline)

            outlines.append(outline)

            var outlineFileText = ""

            outlines.append(outline)

            func loadOutline() {
                if let loadedText = try? String(contentsOf: outlineURL, encoding: .utf8) {
                    outlineFileText = loadedText
                    if outlineFileText != outline.serialize(nil) {
                        outline.reloadSerialization(outlineFileText, options: nil)
                    }
                } else {
                    Swift.print("[Configuration Outline] failed load: \(outlineURL)")
                }
            }

            func saveOutline() {
                let newOutlineText = outline.serialize(nil)
                if newOutlineText != outlineFileText {
                    _ = try? newOutlineText.write(to: outlineURL, atomically: true, encoding: .utf8)
                }
            }

            subscriptions.append(outline.onDidEndChanges { _ in
                saveOutline()
            })

            let outlineFileMonitorDebouncer = Debouncer(delay: 0.1) {
                loadOutline()
            }

            let outlineFileMonitor = PathMonitor(URL: outlineURL, callback: {
                DispatchQueue.main.async {
                    outlineFileMonitorDebouncer.call()
                }
            })

            fileMonitors.append(outlineFileMonitor)

            loadOutline()

            outlineFileMonitor.startFileMonitoring()
        }
    }

    static func initConfigurationOutlines() {
        initConfigurationOutline("searches.taskpaper", jsOutline: BirchOutline.sharedContext.jsSearchesConfigurationOutline)
        initConfigurationOutline("tags.taskpaper", jsOutline: BirchOutline.sharedContext.jsTagsConfigurationOutline)
    }
}
