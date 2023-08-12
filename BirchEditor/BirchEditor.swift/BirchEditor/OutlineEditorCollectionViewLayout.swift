//
//  OutlineEditorCollectionViewLayout.swift
//  Birch
//
//  Created by Jesse Grosjean on 2/2/17.
//
//

import BirchOutline
import Cocoa

class OutlineEditorCollectionViewLayout: NSCollectionViewLayout {
    var itemToHeight: [JSValue: CGFloat] = [:]
    var itemPrototype: ItemViewController

    init(outlineEditor: OutlineEditorType?) {
        let nib = NSNib(nibNamed: "ItemViewController", bundle: nil)
        var topLevelObjects: NSArray?
        nib?.instantiate(withOwner: nil, topLevelObjects: &topLevelObjects)
        itemPrototype = (topLevelObjects!.filter { item -> Bool in item is ItemViewController }).first as! ItemViewController
        super.init()
        self.outlineEditor = outlineEditor
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var itemCount: Int {
        return collectionView?.numberOfItems(inSection: 0) ?? 0
    }

    weak var outlineEditor: OutlineEditorType? {
        didSet {
            invalidateLayout()
        }
    }

    override func invalidateLayout() {
        super.invalidateLayout()
    }

    override func invalidateLayout(with context: NSCollectionViewLayoutInvalidationContext) {
        super.invalidateLayout(with: context)
    }

    override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: NSCollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: NSCollectionViewLayoutAttributes) -> Bool {
        return super.shouldInvalidateLayout(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)
    }

    /* override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
         let oldBounds = collectionView!.bounds
         if newBounds.width != oldBounds.width {
             return true
         }
         return false
     } */

    func itemHeight(item: ItemType) -> CGFloat {
        if let height = itemToHeight[item as! JSValue] {
            return height
        }
        return 0
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> NSCollectionViewLayoutAttributes? {
        let attributes = NSCollectionViewLayoutAttributes(forItemWith: indexPath)

        guard
            let collectionView = collectionView,
            let outlineEditor = outlineEditor
        else {
            return attributes
        }

        let row = indexPath.item
        let item = outlineEditor.displayedItem(at: row)

        itemPrototype.representedObject = item

        let width = collectionView.bounds.width
        let height = itemPrototype.itemView.heightFor(width: width)
        let itemYOffset = outlineEditor.displayedItemYOffset(at: row)

        outlineEditor.setDisplayedItemHeight(height, at: row)
        attributes.frame = NSRect(x: 0, y: itemYOffset, width: width, height: height)
        // attributes.zIndex = row

        return attributes
    }

    override open func layoutAttributesForElements(in rect: NSRect) -> [NSCollectionViewLayoutAttributes] {
        var attributes = [NSCollectionViewLayoutAttributes]()

        if itemCount > 0 {
            let start = outlineEditor?.displayedItemIndexAtYOffset(at: rect.minY - rect.height) ?? 0
            let end = outlineEditor?.displayedItemIndexAtYOffset(at: rect.maxY + rect.height) ?? 0

            for index in start ... end {
                if let attribute = layoutAttributesForItem(at: NSIndexPath(forItem: index, inSection: 0) as IndexPath) {
                    attributes.append(attribute)
                }
            }
        }

        return attributes
    }

    override open var collectionViewContentSize: NSSize {
        return NSSize(width: collectionView?.bounds.width ?? 0, height: outlineEditor?.heightOfDisplayedItems ?? 0)
    }
}
