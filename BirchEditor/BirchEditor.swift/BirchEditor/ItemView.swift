//
//  ItemView.swift
//  Birch
//
//  Created by Jesse Grosjean on 2/3/17.
//
//

import Cocoa
import CoreText

class ItemView: NSView {
    let _backingStore = NSMutableAttributedString()
    var _framesetter: CTFramesetter?
    var _frame: CTFrame?

    // MARK: LifeCycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.borderColor = NSColor.red.cgColor
        layer?.borderWidth = 0.1
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        _framesetter = nil
        _frame = nil
    }

    // MARK: Text

    var string: String {
        get {
            return _backingStore.string
        }
        set {
            replaceCharacters(in: NSMakeRange(0, _backingStore.length), with: newValue)
        }
    }

    var attributedString: NSAttributedString {
        get {
            return _backingStore
        }
        set {
            replaceCharacters(in: NSMakeRange(0, _backingStore.length), with: newValue)
        }
    }

    public func replaceCharacters(in range: NSRange, with string: Any) {
        _backingStore.beginEditing()
        _backingStore.replaceCharacters(in: range, with: string)

        if range.location == 0 {
            let length = _backingStore.length
            if length > 0 {
                if _backingStore.attribute(NSAttributedString.Key.paragraphStyle, at: 0, effectiveRange: nil) == nil {
                    _backingStore.addAttribute(NSAttributedString.Key.paragraphStyle, value: NSParagraphStyle.default, range: NSMakeRange(0, 1))
                }
            }
        }

        _backingStore.fixAttributes(in: NSMakeRange(range.location, stringLength(string)))
        _backingStore.endEditing()
        _framesetter = nil
        _frame = nil

        // selectionRange = NSMakeRange(0, _backingStore.length)
        needsDisplay = true
    }

    // MARK: Selection

    var selectionRange: NSRange? {
        didSet {
            if oldValue != selectionRange {
                needsDisplay = true
            }
        }
    }

    // MARK: Frame Geometry

    override var frame: NSRect {
        didSet {
            if oldValue != frame {
                invalidateIntrinsicContentSize()
                needsDisplay = true
                _frame = nil
            }
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        invalidateIntrinsicContentSize()
        needsDisplay = true
        _frame = nil
    }

    func heightFor(width: CGFloat) -> CGFloat {
        assert(width > 0)
        let constraints = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let size = ctFramesetter.suggestedFrameSize(constraints: constraints)
        return size.height
    }

    /* This gets called at a number of different times... don't want ot override in colletion view case
     because end up caclulating hieight a few times whne don't need to. Instead using heightFor
     var intrinsicContentSize: NSSize {
     let constraints = CGSize(width: max(bounds.width, 100), height: CGFloat.greatestFiniteMagnitude)
     let size = ctFramesetter.suggestedFrameSize(constraints: constraints)
     return NSSize(width: constraints.width, height: size.height)
     }*/

    // MARK: Text Geometry

    func pick(point: CGPoint) -> (index: Int, affinity: NSSelectionAffinity) {
        let index = closestIndex(to: point)
        return (
            index: index,
            affinity: affinity(for: index, point: point)
        )
    }

    func closestIndex(to point: CGPoint) -> Int {
        guard let lines = ctFrame.lines else {
            return attributedString.length
        }

        let origins = ctFrame.lineOrigins(for: CFRangeMake(0, lines.count))
        for (lineIndex, line) in lines.enumerated() {
            if point.y > origins[lineIndex].y {
                return line.stringIndex(for: point)
            }
        }

        return attributedString.length
    }

    func affinity(for index: Int, point: CGPoint) -> NSSelectionAffinity {
        guard
            let upstreamRect = caretRect(for: index, affinity: .upstream),
            let downstreamRect = caretRect(for: index, affinity: .downstream) else {
            return .downstream
        }

        let upstreamDist = point.distance(to: upstreamRect.center)
        let downstreamDist = point.distance(to: downstreamRect.center)

        if downstreamDist <= upstreamDist {
            return .downstream
        } else {
            return .upstream
        }
    }

    func caretRect(for index: Int, affinity: NSSelectionAffinity? = .downstream) -> CGRect? {
        guard attributedString.length != 0, let lines = ctFrame.lines else {
            return bounds
        }

        let affinity = affinity ?? .downstream

        for (lineIndex, line) in lines.enumerated() {
            let lineRange = line.stringRange
            let localIndex = index - lineRange.location
            let isLastLine = lineIndex == lines.count - 1
            let isEndOfLine = localIndex == lineRange.length
            let isInLine = localIndex >= 0 && localIndex <= lineRange.length

            if isInLine, isLastLine || !isEndOfLine || (isEndOfLine && affinity == .upstream) {
                let xPos = line.offset(for: index)
                let origin = ctFrame.lineOrigins(for: CFRangeMake(lineIndex, 1))[0]
                let typographicBounds = line.typographicBounds()
                return CGRect(x: xPos, y: origin.y - typographicBounds.descent, width: 0, height: typographicBounds.height)
            }
        }

        return nil
    }

    func firstRect(for range: NSRange) -> CGRect? {
        return lineRects(for: range, count: 1)?[0]
    }

    func lineRects(for range: NSRange? = nil, count: Int? = nil) -> [CGRect]? {
        guard let lines = ctFrame.lines else {
            return nil
        }

        var rects: [CGRect] = []
        let range = range ?? NSMakeRange(0, _backingStore.length)

        for (lineIndex, line) in lines.enumerated() {
            let lineRange = line.stringRange
            if let intersection = range.intersection(range: lineRange) {
                let xStart = line.offset(for: intersection.location)
                let xEnd = line.offset(for: intersection.max)
                let typographicBounds = line.typographicBounds()
                let origin = ctFrame.lineOrigins(for: CFRangeMake(lineIndex, 1))[0]
                let rect = CGRect(x: xStart, y: origin.y - typographicBounds.descent, width: xEnd - xStart, height: typographicBounds.height)
                rects.append(rect)
                if rects.count == count {
                    return rects
                }
            }
        }

        return rects
    }

    // MARK: Rendering

    override func draw(_ dirtyRect: NSRect) {
        guard let cgContext = NSGraphicsContext.current?.cgContext else {
            return
        }
        render(cgContext: cgContext, ctFrame: ctFrame, selectionRange: selectionRange, dirtyRect: dirtyRect)
    }

    func render(cgContext: CGContext, ctFrame: CTFrame, selectionRange: NSRange?, dirtyRect _: NSRect? = nil) {
        if let selectionRange = selectionRange {
            renderSelection(range: selectionRange)
        }

        cgContext.textMatrix = .identity
        CTFrameDraw(ctFrame, cgContext)
    }

    func renderSelection(range: NSRange) {
        guard range.location != NSNotFound, let rects = lineRects(for: range) else {
            return
        }

        NSColor.blue.withAlphaComponent(0.5).set()

        for each in rects {
            each.fill()
        }
    }

    // MARK: Core Text

    var ctFramesetter: CTFramesetter {
        if let framesetter = _framesetter {
            return framesetter
        }
        _framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        return _framesetter!
    }

    var ctFrame: CTFrame {
        if let frame = _frame {
            return frame
        }
        let rect = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        let path = CGPath(rect: rect, transform: nil)
        _frame = CTFramesetterCreateFrame(ctFramesetter, CFRangeMake(0, 0), path, nil)
        return _frame!
    }
}

func stringLength(_ string: Any) -> Int {
    return (string as? NSString)?.length ?? (string as? NSAttributedString)?.length ?? 0
}
