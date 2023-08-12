//
//  ItemPasteboardUtilities.swifts.swift
//  BirchEditor
//
//  Created by Jesse Grosjean on 7/10/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

extension NSPasteboard.PasteboardType {
    static let itemReference: NSPasteboard.PasteboardType = NSPasteboard.PasteboardType("com.hogbaysoftware.ItemReferencePboardType")
    static let backwardsCompatibleFileURL: NSPasteboard.PasteboardType = {
        if #available(OSX 10.13, *) {
            return NSPasteboard.PasteboardType.fileURL
        } else {
            return NSPasteboard.PasteboardType(kUTTypeFileURL as String)
        }
    }()
}

open class ItemPasteboardUtilities {
    open class var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        return [
            .itemReference,
            .backwardsCompatibleFileURL,
            NSPasteboard.PasteboardType(kUTTypeURL as String),
            NSPasteboard.PasteboardType(kUTTypeUTF8PlainText as String),
            NSPasteboard.PasteboardType(kUTTypePlainText as String),
            // NSPasteboardTypeString
            // NSPasteboard.PasteboardType(NSStringPboardType as String),
        ]
    }

    open class func readItemsSerializedItemReferences(_ pasteboardItem: NSPasteboardItem, editor: OutlineEditorType) -> [ItemType]? {
        if let serializedItemReferences = pasteboardItem.string(forType: .itemReference) {
            return editor.deserializeItems(serializedItemReferences, options: ["type": NSPasteboard.PasteboardType.itemReference.rawValue])
        }
        return nil
    }

    open class func readItemsFromPasteboard(_ pasteboard: NSPasteboard, type: NSPasteboard.PasteboardType, editor: OutlineEditorType) -> [ItemType]? {
        var strings: String? = ""

        if type == NSPasteboard.PasteboardType.itemReference {
            strings = pasteboard.string(forType: type)
        } else {
            strings = pasteboard.readObjects(forClasses: [NSURL.self, NSString.self])?.makeIterator().compactMap { each -> String? in
                if let each = (each as? NSURL)?.absoluteURL {
                    return each.absoluteString
                } else if let each = each as? String {
                    return each
                } else {
                    return nil
                }
            }.joined(separator: "\n")
        }

        if let strings = strings, strings.count > 0 {
            return editor.deserializeItems(strings, options: ["type": type])
        }

        return nil
    }

    open class var writablePasteboardTypes: [NSPasteboard.PasteboardType] {
        return [
            NSPasteboard.PasteboardType(kUTTypeUTF8PlainText as String),
            NSPasteboard.PasteboardType(kUTTypePlainText as String),
        ]
    }

    open class func itemsDragOperationForDraggingInfo(_ dragInfo: NSDraggingInfo, editor: OutlineEditorType, parent: ItemType?, nextSibling: ItemType?) -> NSDragOperation {
        guard let parent = parent else {
            return []
        }

        let sourceDragMask = dragInfo.draggingSourceOperationMask
        let pasteboard = dragInfo.draggingPasteboard

        guard let types = pasteboard.types else {
            return []
        }

        if types.contains(.itemReference) {
            guard let items = readItemsFromPasteboard(pasteboard, type: .itemReference, editor: editor) else {
                return []
            }

            if items.count == 0 {
                return []
            }

            if sourceDragMask.contains(.move) {
                var allowMove = true
                for each in items {
                    if each === parent {
                        allowMove = false
                    } else if each.contains(parent) {
                        allowMove = false
                    } else {
                        if each.parent === parent {
                            if each === nextSibling {
                                return []
                            } else if nextSibling === nil, each === parent.lastChild {
                                return []
                            } else if nextSibling?.previousSibling === each {
                                return []
                            }
                        }
                    }

                    if !allowMove {
                        break
                    }
                }

                if allowMove {
                    return .move
                }
            }

            if sourceDragMask.contains(.copy) {
                return .copy
            }
        }

        return .generic
    }

    open class func itemsPerformDragOperation(_ dragInfo: NSDraggingInfo, editor: OutlineEditorType, parent: ItemType, nextSibling: ItemType?) -> Bool {
        let dragOperation = itemsDragOperationForDraggingInfo(dragInfo, editor: editor, parent: parent, nextSibling: nextSibling)
        let pasteboard = dragInfo.draggingPasteboard

        guard let types = pasteboard.types else {
            return false
        }

        for each in readablePasteboardTypes {
            if types.contains(each) {
                var items: [ItemType]?

                if each == .itemReference {
                    items = readItemsFromPasteboard(pasteboard, type: .itemReference, editor: editor)
                    if let itemsToCopy = items {
                        if dragOperation.contains(.copy) {
                            let jsOutline = itemsToCopy.first!.jsOutline
                            let jsItems = JSValue.fromItemTypeArray(itemsToCopy, context: jsOutline.context)
                            let jsItemsClone = jsOutline.invokeMethod("cloneItems", withArguments: [jsItems, true])
                            items = jsItemsClone!.toItemTypeArray()
                        }
                    }
                } else {
                    items = readItemsFromPasteboard(pasteboard, type: each, editor: editor)
                }

                if let items = items {
                    editor.moveBranches(items, parent: parent, nextSibling: nextSibling, options: nil)
                    return true
                }
            }
        }

        return false
    }
}
