import AppKit
import Foundation

class ChoicePaletteTableCellView: NSTableCellView {
    
    @IBOutlet var titleTextField: NSTextField!
    @IBOutlet var detailTextField: NSTextField!
    @IBOutlet var indentationLayoutConstraint: NSLayoutConstraint!

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            updateLabelColors()
        }
    }

    func updateLabelColors() {
        if backgroundStyle == .normal {
            titleTextField.textColor = NSColor.controlTextColor
            detailTextField.textColor = NSColor.controlTextColor
        } else if backgroundStyle == .emphasized {
            titleTextField.textColor = NSColor.alternateSelectedControlTextColor
            detailTextField.textColor = NSColor.alternateSelectedControlTextColor
        }
    }
    
}
