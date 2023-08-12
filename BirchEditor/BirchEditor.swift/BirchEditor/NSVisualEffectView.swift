//
//  NSVisualEffectView-Colors.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/7/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

extension NSView {
    var enclosingVisualEffectView: NSVisualEffectView? {
        var each = superview
        while each != nil {
            if let visualEffectView = each as? NSVisualEffectView {
                return visualEffectView
            }
            each = each?.superview
        }
        return nil
    }
}

/*
  Doesn't work on 10.12, layer names are gone, instead seems to be private API in NSVisualEffectView to access these layers
 extension NSVisualEffectView {

     var backdropColor: CGColor? {
         get {
             return layer?.layerNamed("Backdrop")?.backgroundColor
         }
         set(color) {
             delay(1) { [weak self] in
                 self?.layer?.layerNamed("Backdrop")?.backgroundColor = color
             }
         }
     }

     var tintColor: CGColor? {
         get {
             return layer?.layerNamed("Tint")?.backgroundColor
         }
         set(color) {
             delay(1) { [weak self] in
                 self?.layer?.layerNamed("Tint")?.backgroundColor = color
             }
         }
     }

 }
 */
