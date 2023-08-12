//
//  SearchBarButtonCell.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 8/9/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

class SearchBarSegmentedCell: NSSegmentedCell {
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        drawInterior(withFrame: cellFrame, in: controlView)
    }
}
