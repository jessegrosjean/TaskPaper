//
//  CoreText-Extensions.swift
//  TextInputClientText
//
//  Created by Jesse Grosjean on 2/10/17.
//  Copyright © 2017 Jesse Grosjean. All rights reserved.
//

import CoreText

extension CTFramesetter {
    func suggestedFrameSize(for stringRange: CFRange? = nil, frameAttributes: CFDictionary? = nil, constraints: CGSize) -> CGSize {
        let range = stringRange ?? CFRange(location: 0, length: 0)
        return CTFramesetterSuggestFrameSizeWithConstraints(self, range, frameAttributes, constraints, nil)
    }
}

extension CTFrame {
    var path: CGPath {
        return CTFrameGetPath(self)
    }

    var lines: [CTLine]? {
        return CTFrameGetLines(self) as? [CTLine]
    }

    var textHeight: CGFloat {
        guard
            let lines = lines,
            let firstLine = lines.first,
            let lastLine = lines.last
        else {
            return 0
        }

        let topY = lineOrigins(for: CFRangeMake(0, 1))[0].y + firstLine.typographicBounds().ascent
        let bottomY = lineOrigins(for: CFRangeMake(lines.count - 1, 1))[0].y - lastLine.typographicBounds().descent
        return topY - bottomY
    }

    func lineOrigins(for lineRange: CFRange) -> [CGPoint] {
        var origins = [CGPoint](repeating: CGPoint.zero, count: lineRange.length)
        CTFrameGetLineOrigins(self, lineRange, &origins)
        return origins
    }
}

struct TypographicBounds {
    var ascent: CGFloat
    var descent: CGFloat
    var leading: CGFloat
    var height: CGFloat {
        return ascent + descent + leading
    }
}

extension CTLine {
    var stringRange: CFRange {
        return CTLineGetStringRange(self)
    }

    func stringIndex(for position: CGPoint) -> Int {
        return CTLineGetStringIndexForPosition(self, position)
    }

    func offset(for stringIndex: Int) -> CGFloat {
        return CTLineGetOffsetForStringIndex(self, stringIndex, nil)
    }

    func typographicBounds() -> TypographicBounds {
        var bounds = TypographicBounds(ascent: 0, descent: 0, leading: 0)
        CTLineGetTypographicBounds(self, &bounds.ascent, &bounds.descent, &bounds.leading)
        return bounds
    }
}
