//
//  TaskPaperDocument.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 6/10/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import BirchOutline
import Cocoa

class TaskPaperDocument: OutlineDocument {
    override func instantiateWindowController() -> OutlineEditorWindowController {
        let storyboard = NSStoryboard(name: "OutlineEditorWindow", bundle: nil)
        return storyboard.instantiateController(withIdentifier: "Outline Editor Window Controller") as! OutlineEditorWindowController
    }

    override var outlineRuntimeType: String {
        return "com.taskpaper.text"
    }
}
