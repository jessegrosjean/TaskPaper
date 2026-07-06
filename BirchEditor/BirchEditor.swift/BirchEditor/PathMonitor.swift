//
//  FileMonitor.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/4/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Darwin
import Foundation

@MainActor
class PathMonitor {
    var monitoredFileDescriptor: CInt?
    var pathMonitorSource: DispatchSourceFileSystemObject?
    var callback: () -> Void
    var flags: DispatchSource.FileSystemEvent?
    var restart = true
    var URL: Foundation.URL

    init(URL: Foundation.URL, callback: @escaping () -> Void) {
        self.URL = URL
        self.callback = callback
    }

    deinit {
        // deinit is nonisolated, but every owner of a PathMonitor is a
        // main-actor-isolated static, so the last release happens on main.
        MainActor.assumeIsolated {
            stopMonitoring()
        }
    }

    func startDirectoryMonitoring() {
        startMonitoring(.write)
    }

    func startFileMonitoring() {
        startMonitoring([.delete, .write, .extend, .attrib, .link, .rename, .revoke])
    }

    func startMonitoring(_ flags: DispatchSource.FileSystemEvent) {
        self.flags = flags

        if pathMonitorSource == nil, monitoredFileDescriptor == nil {
            let path = URL.path
            monitoredFileDescriptor = open(path, O_EVTONLY)
            // Hack to support edits from vim (and maybe other apps)
            // When they save they seem to:
            // 1. Rename existing file to existingfile~
            // 2. Delete existingfile~
            // This code maps existingfile~ back to existingfile if present
            if monitoredFileDescriptor == -1, path.hasSuffix("~") {
                let trimmedPath = String(path[..<path.index(before: path.endIndex)])
                monitoredFileDescriptor = open(trimmedPath, O_EVTONLY)
                if monitoredFileDescriptor != -1 {
                    URL = Foundation.URL(fileURLWithPath: trimmedPath)
                }
            }

            if monitoredFileDescriptor != -1 {
                // Deliver events on the main queue: the event handler mutates
                // monitor state that startMonitoring/stopMonitoring touch from
                // the main thread, and every callback ends up mutating
                // main-thread state (script commands, configuration outlines).
                // A private queue here raced against both.
                pathMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFileDescriptor!, eventMask: flags, queue: .main)
                if let pathMonitorSource = pathMonitorSource {
                    // Both handlers run on the main queue (source queue above);
                    // assumeIsolated enforces that at runtime.
                    pathMonitorSource.setEventHandler { [unowned self] in
                        MainActor.assumeIsolated {
                            if let flags = self.pathMonitorSource?.data {
                                if flags.contains(.delete) {
                                    self.stopMonitoring()
                                    self.restart = true
                                } else if flags.contains(.rename) {
                                    if let newPath = getFileDescriptorPath(self.monitoredFileDescriptor!) {
                                        self.URL = Foundation.URL(fileURLWithPath: newPath)
                                    } else {
                                        self.stopMonitoring()
                                        self.restart = false
                                    }
                                }
                            }
                            self.callback()
                        }
                    }

                    pathMonitorSource.setCancelHandler { [weak self] in
                        MainActor.assumeIsolated {
                            if let strongSelf = self {
                                close(strongSelf.monitoredFileDescriptor!)
                                strongSelf.monitoredFileDescriptor = nil
                                strongSelf.pathMonitorSource = nil
                                if strongSelf.restart {
                                    strongSelf.startMonitoring(self!.flags!)
                                }
                            }
                        }
                    }

                    pathMonitorSource.resume()
                }
            } else {
                monitoredFileDescriptor = -1
            }
        }
    }

    func stopMonitoring() {
        restart = false
        pathMonitorSource?.cancel()
    }
}
