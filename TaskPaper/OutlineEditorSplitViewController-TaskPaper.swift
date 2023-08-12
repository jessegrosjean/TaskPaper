//
//  TaskPaperOutlineViewController.swift
//  TaskPaper
//
//  Created by Jesse Grosjean on 7/12/16.
//  Copyright © 2005–2018 Jesse Grosjean. All rights reserved.
//

import Cocoa

extension OutlineEditorSplitViewController {
    @IBAction func newProject(_: Any?) {
        outlineEditor?.performCommand("outline-editor:new-project", options: nil)
    }

    @IBAction func newTask(_: Any?) {
        outlineEditor?.performCommand("outline-editor:new-task", options: nil)
    }

    @IBAction func newNote(_: Any?) {
        outlineEditor?.performCommand("outline-editor:new-note", options: nil)
    }

    @IBAction func archiveDone(_: Any?) {
        outlineEditor?.performCommand("outline-editor:archive-done", options: nil)
    }

    @IBAction func importReminders(_: Any?) {
        outlineEditor?.performCommand("outline-editor:import-reminders", options: nil)
    }

    @IBAction func importReminderCopies(_: Any?) {
        outlineEditor?.performCommand("outline-editor:import-reminder-copies", options: nil)
    }
}
