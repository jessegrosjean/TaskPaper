//
//  NSFileManager-UserPaths.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/4/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

extension FileManager {
    public func URLForApplicationsSupportDirectory(inDomain domain: FileManager.SearchPathDomainMask, appropriateForURL url: URL?, create shouldCreate: Bool) throws -> URL {
        let supportDirectory = try self.url(for: .applicationSupportDirectory, in: domain, appropriateFor: url, create: shouldCreate)
        let applicationsSupportDirectory = supportDirectory.appendingPathComponent(ProcessInfo.processInfo.processName)
        if shouldCreate && !fileExists(atPath: applicationsSupportDirectory.absoluteString) {
            _ = try? createDirectory(at: applicationsSupportDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return applicationsSupportDirectory
    }

    public func URLForApplicationsStyleSheetsDirectory(inDomain domain: FileManager.SearchPathDomainMask, appropriateForURL url: URL?, create shouldCreate: Bool) throws -> URL {
        let supportDirectory = try self.url(for: .applicationSupportDirectory, in: domain, appropriateFor: url, create: shouldCreate)
        let applicationsSupportDirectory = supportDirectory.appendingPathComponent(ProcessInfo.processInfo.processName)
        let applicationStyleSheetsDirectory = applicationsSupportDirectory.appendingPathComponent("StyleSheets")
        if shouldCreate && !fileExists(atPath: applicationStyleSheetsDirectory.absoluteString) {
            _ = try? createDirectory(at: applicationStyleSheetsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return applicationStyleSheetsDirectory
    }

    public func URLForApplicationsConfigurationsDirectory(inDomain domain: FileManager.SearchPathDomainMask, appropriateForURL url: URL?, create shouldCreate: Bool) throws -> URL {
        let supportDirectory = try self.url(for: .applicationSupportDirectory, in: domain, appropriateFor: url, create: shouldCreate)
        let applicationsSupportDirectory = supportDirectory.appendingPathComponent(ProcessInfo.processInfo.processName)
        let applicationConfigurationsDirectory = applicationsSupportDirectory.appendingPathComponent("Configurations")
        if shouldCreate && !fileExists(atPath: applicationConfigurationsDirectory.absoluteString) {
            _ = try? createDirectory(at: applicationConfigurationsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return applicationConfigurationsDirectory
    }

    public func URLForApplicationsScriptsDirectory(inDomain domain: FileManager.SearchPathDomainMask, appropriateForURL url: URL?, create shouldCreate: Bool) throws -> URL {
        
        let scriptsDirectory = try self.url(for: .applicationScriptsDirectory, in: domain, appropriateFor: url, create: shouldCreate)
        if shouldCreate && !fileExists(atPath: scriptsDirectory.absoluteString) {
            _ = try? createDirectory(at: scriptsDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        return scriptsDirectory
    }
}
