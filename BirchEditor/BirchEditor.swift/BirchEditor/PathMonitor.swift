//
//  FileMonitor.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/4/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Darwin
import Foundation

class PathMonitor {
    let pathMonitorQueue = DispatchQueue(label: "com.Birch.pathmonitor", attributes: [])
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
        stopMonitoring()
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
                pathMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFileDescriptor!, eventMask: flags, queue: pathMonitorQueue)
                if let pathMonitorSource = pathMonitorSource {
                    pathMonitorSource.setEventHandler { [unowned self] in
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

                    pathMonitorSource.setCancelHandler { [weak self] in
                        if let strongSelf = self {
                            close(strongSelf.monitoredFileDescriptor!)
                            strongSelf.monitoredFileDescriptor = nil
                            strongSelf.pathMonitorSource = nil
                            if strongSelf.restart {
                                strongSelf.startMonitoring(self!.flags!)
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
