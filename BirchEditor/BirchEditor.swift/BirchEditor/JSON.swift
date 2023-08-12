//
//  JSON.swift
//  Birch
//
//  Created by Jesse Grosjean on 5/31/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Foundation

extension String {
    func JSONValue() -> Any? {
        if count == 0 {
            return nil
        }

        do {
            return try JSONSerialization.jsonObject(with: data(using: String.Encoding.utf8)!, options: JSONSerialization.ReadingOptions())
        } catch {
            print(error)
        }

        return nil
    }
}

func JSONRepresentation(_ jsonObject: Any) -> String? {
    do {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions())
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
    } catch {
        print(error)
    }
    return nil
}
