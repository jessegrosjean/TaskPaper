//
//  SURL-ExtendedAttributes.swift
//  Birch
//
//  Created by Jesse Grosjean on 9/8/16.
//
//

import Foundation

extension URL {
    func extendedAttributeString(forName name: String) -> String? {
        if let utf8 = extendedAttribute(forName: name) {
            return String(bytes: utf8, encoding: .utf8)
        }
        return nil
    }

    func extendedAttribute(forName name: String) -> [UInt8]? {
        let path = standardizedFileURL.path
        let length = getxattr(path, name, nil, 0, 0, 0)
        guard length >= 0 else { return nil }
        var data = [UInt8](repeating: 0, count: length)
        let result = getxattr(path, name, &data, data.count, 0, 0)
        guard result >= 0 else { return nil }
        return data
    }

    func setExtendedAttribute(string: String, forName name: String) -> Bool {
        return setExtendedAttribute(data: [UInt8](string.utf8), forName: name)
    }

    // Set extended attribute. Returns `true` on success and `false` on failure.
    func setExtendedAttribute(data: [UInt8], forName name: String) -> Bool {
        let path = standardizedFileURL.path
        let result = data.withUnsafeBufferPointer {
            setxattr(path, name, $0.baseAddress, data.count, 0, 0)
        }
        return result == 0
    }

    // Remove extended attribute. Returns `true` on success and `false` on failure.
    func removeExtendedAttribute(forName name: String) -> Bool {
        let path = standardizedFileURL.path
        let result = removexattr(path, name, 0)
        return result == 0
    }
}
