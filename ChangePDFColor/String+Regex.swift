//
//  String+Regex.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/17.
//

import Foundation

extension String {
    func regexMatch(pattern: String, options: NSRegularExpression.Options = []) -> [String] {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        let matches = regex.matches(in: self, options: [], range: NSRange(self.startIndex...,in: self))
        return matches.map { match in
            String(self[Range(match.range, in: self)!])
        }
    }

    func regexReplace(pattern: String, with: String, options: NSRegularExpression.Options = []) -> String {
        let regex = try! NSRegularExpression(pattern: pattern, options: options)
        return regex.stringByReplacingMatches(in: self, options: [],
                                                      range: NSMakeRange(0, self.count),
                                                      withTemplate: with)
    }
}

extension String {
    var isPng: Bool {
        URL(fileURLWithPath: self).pathExtension.regexMatch(pattern: "^png$", options: [.caseInsensitive]).count != 0
    }

    var isPdf: Bool {
        URL(fileURLWithPath: self).pathExtension.regexMatch(pattern: "^pdf$", options: [.caseInsensitive]).count != 0
    }
}
