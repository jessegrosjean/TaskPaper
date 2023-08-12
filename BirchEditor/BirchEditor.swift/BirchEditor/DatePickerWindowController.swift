//
//  DatePickerWindowController.swift
//  Birch
//
//  Created by Jesse Grosjean on 10/18/16.
//
//

import Cocoa

let datePickerBundle = Bundle(for: DatePickerWindowController.self)
let datePickerStoryboard = NSStoryboard(name: "DatePicker", bundle: datePickerBundle)

class DatePickerWindowController: NSWindowController {
    var isClosingWindowAfterPerformingCommand = 0

    internal static func showDatePicker(_ window: NSWindow?, placeholder: String, dateStringTemplate: String? = nil, completionHandler: (((Date)?) -> Void)?) {
        let datePickerWindowController = datePickerStoryboard.instantiateController(withIdentifier: "Date Picker Window Controller") as! DatePickerWindowController

        datePickerWindowController.loadWindow()

        let hostWindowLevel = window?.level ?? .normal
        if let datePicker = datePickerWindowController.window, datePicker.level < hostWindowLevel {
            datePicker.level = hostWindowLevel + 1
        }

        if let viewController = datePickerWindowController.datePickerViewController {
            viewController.placeholderString = placeholder
            if let template = dateStringTemplate {
                viewController.dateTextTemplate = template
            }
            datePickerWindowController.window?.layoutIfNeeded()
            viewController.completionHandler = { date in
                datePickerWindowController.isClosingWindowAfterPerformingCommand += 1
                datePickerWindowController.window?.close()
                datePickerWindowController.isClosingWindowAfterPerformingCommand -= 1
                completionHandler?(date)
            }
        }

        datePickerWindowController.window?.centerOnWindow(window)
        datePickerWindowController.showWindow(nil)
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResignKey(_:)), name: NSWindow.didResignKeyNotification, object: window)
    }

    var datePickerViewController: DatePickerViewController? {
        return contentViewController as? DatePickerViewController
    }

    @objc func windowDidResignKey(_: Notification) {
        if isClosingWindowAfterPerformingCommand == 0 {
            datePickerViewController?.performPickDate(nil)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
