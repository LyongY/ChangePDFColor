//
//  PDFStream.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/16.
//

import Foundation

class PDFStream {
    var preData = Data()
    var suffixData = Data()
    var filterData: Data
    var data: Data { preData + filterData + suffixData }
    var unzippedData: Data
    private var isPlainStream = false
    init(_ data: Data) {
        var filterData = data
        while let first = filterData.first, first == Character("\n").asciiValue || first == Character("\r").asciiValue || first == Character(" ").asciiValue {
            filterData.removeFirst()
            preData.append(first)
        }
        while let last = filterData.last, last == Character("\n").asciiValue || last == Character("\r").asciiValue || last == Character(" ").asciiValue {
            filterData.removeLast()
            suffixData.append(last)
        }
        self.filterData = filterData
        unzippedData = (filterData as NSData).unzipped()
        if unzippedData.isEmpty {
            unzippedData = Data(filterData.map { $0 })
            isPlainStream = true
        }
    }

    var colors: [RGB] {
        var colorArr: [RGB] = []

        let range = PDFAnalyze.Range(start: 0, end: unzippedData.count)
        if let plainStr = string(with: range) {
            let pattern = "((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) scn"
            let matches = plainStr.regexMatch(pattern: pattern, options: [.caseInsensitive])

            for match in matches {
                let oriString = match
                let arr = oriString.components(separatedBy: " ")
                let rgb = RGB(
                    r: Int(Double(arr[0])! * 255),
                    g: Int(Double(arr[1])! * 255),
                    b: Int(Double(arr[2])! * 255)
                )
                if !colorArr.contains(rgb) {
                    colorArr.append(rgb)
                }
            }

            // 匹配 [0.111 0.2222 0.3333] 格式
            do {
                let pattern = "\\[\\s*((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s+((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s+((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s*\\]"
                let matches = plainStr.regexMatch(pattern: pattern)

                for match in matches {
                    var oriString = match
                    oriString = oriString.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                    oriString = oriString.trimmingCharacters(in: .whitespaces)
                    oriString = oriString.regexReplace(pattern: "\\s+", with: " ")
                    let arr = oriString.components(separatedBy: " ")
                    let rgb = RGB(
                        r: Int(Double(arr[0])! * 255),
                        g: Int(Double(arr[1])! * 255),
                        b: Int(Double(arr[2])! * 255)
                    )
                    if !colorArr.contains(rgb) {
                        colorArr.append(rgb)
                    }
                }
            }
        }
        return colorArr
    }

    func change(colors: [RGB2RGB]) {
        let range = PDFAnalyze.Range(start: 0, end: unzippedData.count)
        if let plainStr = string(with: range) {
            var changedStr = plainStr
            do {
                let pattern = "\\[\\s*((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s+((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s+((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s*\\]"
                let matches = plainStr.regexMatch(pattern: pattern)

                for match in matches {
                    var oriString = match
                    oriString = oriString.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                    oriString = oriString.trimmingCharacters(in: .whitespaces)
                    oriString = oriString.regexReplace(pattern: "\\s+", with: " ")
                    let arr = oriString.components(separatedBy: " ")
                    let rgb = RGB(
                        r: Int(Double(arr[0])! * 255),
                        g: Int(Double(arr[1])! * 255),
                        b: Int(Double(arr[2])! * 255)
                    )

                    var changed = false // 只修改一次颜色
                    for colorTouple in colors {
                        if changed { continue }
                        if colorTouple.oriRGB.like(rgb, deviation: colorTouple.deviation) {
                            changed = true
                            let rString = String(format: "%.6g", Double(colorTouple.toRGB.r) / 255)
                            let gString = String(format: "%.6g", Double(colorTouple.toRGB.g) / 255)
                            let bString = String(format: "%.6g", Double(colorTouple.toRGB.b) / 255)
                            changedStr = changedStr.replacingOccurrences(of: match, with: "[ \(rString) \(gString) \(bString) ]")
                        }
                    }
                }
            }

            let pattern = "((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) scn"
            let matches = plainStr.regexMatch(pattern: pattern, options: [.caseInsensitive])

            for match in matches {
                let oriString = match
                let arr = oriString.components(separatedBy: " ")
                let rgb = RGB(
                    r: Int(Double(arr[0])! * 255),
                    g: Int(Double(arr[1])! * 255),
                    b: Int(Double(arr[2])! * 255)
                )

                let lastString = arr[3]

                var changed = false // 只修改一次颜色
                for colorTouple in colors {
                    if changed { continue }
                    if colorTouple.oriRGB.like(rgb, deviation: colorTouple.deviation) {
                        changed = true
                        let rString = String(format: "%.6g", Double(colorTouple.toRGB.r) / 255)
                        let gString = String(format: "%.6g", Double(colorTouple.toRGB.g) / 255)
                        let bString = String(format: "%.6g", Double(colorTouple.toRGB.b) / 255)
                        changedStr = changedStr.replacingOccurrences(of: match, with: "\(rString) \(gString) \(bString) \(lastString)")
                    }
                }
            }

            let changeData = changedStr.data(using: .utf8)!
            unzippedData[range.start..<range.end] = changeData
        }
        if isPlainStream {
            filterData = unzippedData
        } else {
            filterData = (unzippedData as NSData).zipped()
        }
    }

    func string(with lineRange: PDFAnalyze.Range) -> String? {
        let lineData = unzippedData[lineRange.start..<lineRange.end]
        let str = String(data: lineData, encoding: .utf8)
        return str
    }
}
