//
//  DatePickerViewController.swift
//  Birch
//
//  Created by Jesse Grosjean on 10/18/16.
//
//

import BirchOutline
import Cocoa

class DatePickerViewController: NSViewController {
    @IBOutlet var dateTextField: NSTextField!
    @IBOutlet var messageTextField: NSTextField!
    @IBOutlet var datePicker: DatePicker!

    var completionHandler: ((Date?) -> Void)?
    var dateTextTemplate = "%@" {
        didSet {
            updateUI()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.dateValue = Date()
        updateUI()
    }

    var placeholderString: String {
        get {
            return dateTextField.placeholderString ?? ""
        }
        set(value) {
            dateTextField.placeholderString = value
        }
    }

    var date: Date? {
        if dateString.isEmpty {
            return Calendar.autoupdatingCurrent.startOfDay(for: datePicker.dateValue)
        } else {
            return DateTime.parse(dateTime: dateString)
        }
    }

    var dateString: String {
        get {
            return dateTextField.stringValue
        }
        set(value) {
            dateTextField.stringValue = value
            updateUI()
        }
    }

    func performPickDate(_ date: Date?) {
        completionHandler?(date)
        completionHandler = nil
    }

    func updateDateField(newDate: Date) {
        let newDateString = DateTime.format(dateTime: newDate, showMillisecondsIfNeeded: false, showSecondsIfNeeded: false)
        dateTextField.stringValue = newDateString.appending(" ")
        dateTextField.currentEditor()?.moveToEndOfDocument(nil)
        updateUI()
    }

    func updateUI() {
        if let date = date {
            let dateString = DateTime.format(dateTime: date, showMillisecondsIfNeeded: false, showSecondsIfNeeded: false)
            messageTextField.stringValue = String(format: dateTextTemplate, dateString)
            datePicker.dateValue = date
        } else {
            messageTextField.stringValue = NSLocalizedString("Invalid\nTry “next week”", tableName: "DatePicker", comment: "message")
        }
    }

    @IBAction func pickedCalendar(_: AnyObject) {
        updateDateField(newDate: Calendar.autoupdatingCurrent.startOfDay(for: datePicker.dateValue))
        if let event = NSApp.currentEvent, event.clickCount == 2 {
            performPickDate(date)
        }
    }
}

extension DatePickerViewController: NSTextFieldDelegate {
    func controlTextDidChange(_: Notification) {
        updateUI()
    }

    func control(_: NSControl, textView _: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch commandSelector {
        case #selector(moveUp(_:)):
            updateDateField(newDate: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: datePicker.dateValue)!)
            return true
        case #selector(moveDown(_:)):
            updateDateField(newDate: Calendar.current.date(byAdding: .weekOfYear, value: 1, to: datePicker.dateValue)!)
            return true
        case #selector(moveLeft(_:)):
            updateDateField(newDate: Calendar.current.date(byAdding: .day, value: -1, to: datePicker.dateValue)!)
            return true
        case #selector(moveRight(_:)):
            updateDateField(newDate: Calendar.current.date(byAdding: .day, value: 1, to: datePicker.dateValue)!)
            return true
        case #selector(insertNewline(_:)):
            if let date = date {
                performPickDate(date)
            } else {
                NSSound.beep()
            }
            return true
        case #selector(cancelOperation(_:)), #selector(insertTab(_:)), #selector(insertBacktab(_:)):
            performPickDate(nil)
            return true
        default:
            return false
        }
    }
}
