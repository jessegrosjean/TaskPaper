//
//  OutlineEditorCollectionViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 2/2/17.
//
//

import Cocoa

class OutlineEditorCollectionViewController: NSViewController, OutlineEditorHolderType {
    @IBOutlet var collectionView: NSCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = OutlineEditorCollectionViewLayout(outlineEditor: outlineEditor)
    }

    open var outlineEditor: OutlineEditorType? {
        didSet {
            if !isViewLoaded {
                loadView()
            }
            (collectionView.collectionViewLayout as? OutlineEditorCollectionViewLayout)?.outlineEditor = outlineEditor
            collectionView.reloadData()
        }
    }
}

extension OutlineEditorCollectionViewController: NSCollectionViewDelegate {
    func collectionView(_: NSCollectionView, willDisplay _: NSCollectionViewItem, forRepresentedObjectAt _: IndexPath) {}

    func collectionView(_: NSCollectionView, didEndDisplaying _: NSCollectionViewItem, forRepresentedObjectAt _: IndexPath) {}
}

extension OutlineEditorCollectionViewController: NSCollectionViewDataSource {
    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        return outlineEditor?.numberOfDisplayedItems ?? 0
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ItemViewController"), for: indexPath)
        item.representedObject = outlineEditor?.displayedItem(at: indexPath.item)
        return item
    }
}
