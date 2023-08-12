//
//  String.swift
//  Birch
//
//  Created by Jesse Grosjean on 9/7/16.
//
//

import Foundation

struct Regex {
    var pattern: String {
        didSet {
            updateRegex()
        }
    }

    var expressionOptions: NSRegularExpression.Options {
        didSet {
            updateRegex()
        }
    }

    var matchingOptions: NSRegularExpression.MatchingOptions

    var regex: NSRegularExpression?

    init(pattern: String, expressionOptions: NSRegularExpression.Options, matchingOptions: NSRegularExpression.MatchingOptions) {
        self.pattern = pattern
        self.expressionOptions = expressionOptions
        self.matchingOptions = matchingOptions
        updateRegex()
    }

    init(pattern: String) {
        self.pattern = pattern
        expressionOptions = []
        matchingOptions = []
        updateRegex()
    }

    mutating func updateRegex() {
        regex = try? NSRegularExpression(pattern: pattern, options: expressionOptions)
    }
}

extension String {
    func isMatch(_ pattern: Regex) -> Bool {
        return firstMatch(pattern) != nil
    }

    func isMatch(_ patternString: String) -> Bool {
        return isMatch(Regex(pattern: patternString))
    }

    func firstStringMatch(_ pattern: Regex) -> String? {
        let range: NSRange = NSMakeRange(0, utf16.count)
        if pattern.regex != nil {
            if let match = pattern.regex!.firstMatch(in: self, options: pattern.matchingOptions, range: range) {
                return (self as NSString).substring(with: match.range(at: 1))
            }
        }
        return nil
    }

    func firstStringMatch(_ patternString: String) -> String? {
        return firstStringMatch(Regex(pattern: patternString))
    }

    func firstMatch(_ pattern: Regex) -> NSTextCheckingResult? {
        let range: NSRange = NSMakeRange(0, utf16.count)
        if pattern.regex != nil {
            return pattern.regex!.firstMatch(in: self, options: pattern.matchingOptions, range: range)
        }
        return nil
    }

    func match(_ pattern: Regex) -> [NSTextCheckingResult] {
        let range: NSRange = NSMakeRange(0, utf16.count)
        if pattern.regex != nil {
            return pattern.regex!.matches(in: self, options: pattern.matchingOptions, range: range)
        }
        return []
    }

    func match(_ patternString: String) -> [NSTextCheckingResult] {
        return match(Regex(pattern: patternString))
    }

    func replace(_ pattern: Regex, template: String) -> String {
        if isMatch(pattern) {
            let range: NSRange = NSMakeRange(0, utf16.count)
            if pattern.regex != nil {
                return pattern.regex!.stringByReplacingMatches(in: self, options: pattern.matchingOptions, range: range, withTemplate: template)
            }
        }
        return self
    }

    func replace(_ pattern: String, template: String) -> String {
        return replace(Regex(pattern: pattern), template: template)
    }
}
