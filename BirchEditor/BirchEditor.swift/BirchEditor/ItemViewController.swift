//
//  ItemViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 2/2/17.
//
//

import BirchOutline
import Cocoa

class ItemViewController: NSCollectionViewItem {
    @IBOutlet var itemView: ItemView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
            itemView!.string = (representedObject as? ItemType)?.body.appending("\n") ?? "\n"
        }
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: NSCollectionViewLayoutAttributes) -> NSCollectionViewLayoutAttributes {
        return super.preferredLayoutAttributesFitting(layoutAttributes)
    }

    override func apply(_ layoutAttributes: NSCollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
    }
}
