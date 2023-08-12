//
//  CALayer.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/2/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

extension CALayer {
    func layerNamed(_ name: String) -> CALayer? {
        if self.name == name {
            return self
        }

        for each in sublayers ?? [] {
            if let result = each.layerNamed(name) {
                return result
            }
        }

        return nil
    }

    func _subtreeDescription() -> String {
        var result = ""

        func visit(_ layer: CALayer, indent: String) {
            result += "\(indent)<\(layer.className)"

            if let name = layer.name {
                result += " name=\(name)"
            }

            if layer.isHidden {
                result += " hidden=true"
            }

            result += " frame=\(layer.frame)"

            if let backgroundColor = layer.backgroundColor {
                let components = backgroundColor.components
                result += " backgroundColor=(\(String(format: "%.1f", (components?[0])!)), \(String(format: "%.1f", (components?[1])!)), \(String(format: "%.1f", (components?[2])!)), \(String(format: "%.1f", (components?[3])!)))"
            }

            if let shadowColor = layer.shadowColor {
                let components = shadowColor.components
                if components?[0] != 0 || components?[1] != 0 || components?[2] != 0 || components?[3] != 1 {
                    result += " shadowColor=(\(String(format: "%.1f", (components?[0])!)), \(String(format: "%.1f", (components?[1])!)), \(String(format: "%.1f", (components?[2])!)), \(String(format: "%.1f", (components?[3])!)))"
                }
            }

            if let filters = layer.filters, filters.count > 0 {
                result += " filters=\(filters)"
            }

            if let compositingFilter = layer.compositingFilter {
                result += " compositingFilter=\(compositingFilter)"
            }

            if let backgroundFilters = layer.backgroundFilters, backgroundFilters.count > 0 {
                result += " backgroundFilters=\(backgroundFilters)"
            }

            result += ">\n"

            let childIndent = "\t\(indent)"
            for each in layer.sublayers ?? [] {
                visit(each, indent: childIndent)
            }
        }

        visit(self, indent: "")

        return result
    }
}
