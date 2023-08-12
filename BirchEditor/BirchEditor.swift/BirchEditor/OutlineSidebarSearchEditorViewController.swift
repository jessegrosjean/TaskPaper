//
//  OutlineSidebarSearchEditorViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 9/7/16.
//
//

import BirchOutline
import Cocoa

class OutlineSidebarSearchEditorViewController: NSViewController {
    @IBOutlet var titleTextField: NSTextField!

    @objc var label: String = ""
    @objc var search: String = ""
    @objc var embedded: Bool = false
    var creatingNew: Bool = false
    var completionCallback: ((String, String, Bool) -> Void)?

    @objc var validated: Bool {
        return label.utf16.count > 0 && search.utf16.count > 0
    }

    @objc class func keyPathsForValuesAffectingValidated() -> Set<String> {
        return ["label", "search"]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if creatingNew {
            titleTextField.stringValue = NSLocalizedString("New Search", tableName: "SavedSearchSheet", comment: "label")
        } else {
            titleTextField.stringValue = NSLocalizedString("Edit Search", tableName: "SavedSearchSheet", comment: "label")
        }
    }

    @IBAction func ok(_ sender: Any?) {
        completionCallback?(label, search, embedded)
        dismiss(sender)
    }
}
