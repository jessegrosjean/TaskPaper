//
//  String-Path.swift
//  BirchOutline
//
//  Created by Jesse Grosjean on 7/10/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

public extension String {
        
    var lastPathComponent: String {
        get {
            return (self as NSString).lastPathComponent
        }
    }
    
    var pathExtension: String {
        get {
            return (self as NSString).pathExtension
        }
    }
    
    var stringByDeletingLastPathComponent: String {
        get {
            return (self as NSString).deletingLastPathComponent
        }
    }
    
    var stringByDeletingPathExtension: String {
        get {
            return (self as NSString).deletingPathExtension
        }
    }
    
    var pathComponents: [String] {
        get {
            return (self as NSString).pathComponents
        }
    }
    
    func stringByAppendingPathComponent(_ path: String) -> String {
        let nsSt = self as NSString
        return nsSt.appendingPathComponent(path)
    }
    
    func stringByAppendingPathExtension(_ ext: String) -> String? {
        let nsSt = self as NSString
        return nsSt.appendingPathExtension(ext)
    }
    
}
