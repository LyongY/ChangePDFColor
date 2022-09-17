//
//  PDFNotStream.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/17.
//

import Foundation

class PDFNotStream {
    var data: Data
    init(_ data: Data) {
        self.data = data
    }

    var colors: [RGB] {
        var colorArr: [RGB] = []

        for range in readColor() {
            if let plainStr = PDFAnalyze.string(data, with: range) {
                // 匹配 [0.111 0.2222 0.3333] 格式
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
        let lineRangeArr = NSMutableArray(array: readColor())
        for (_, range) in lineRangeArr.enumerated() {
            let range = range as! PDFAnalyze.Range
            if let plainStr = PDFAnalyze.string(data, with: range) {
                var changedStr = plainStr

                let pattern = "\\[\\s*((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s+((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s+((0)|(1)|(0\\.\\d+)|(1\\.0+))\\s*\\]"
                let matches = plainStr.regexMatch(pattern: pattern)

                for match in matches {
                    var oriString = match
                    oriString = oriString.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                    oriString = oriString.trimmingCharacters(in: .whitespaces)
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
                            changedStr = changedStr.replacingOccurrences(of: match, with: "[\(rString) \(gString) \(bString)]")
                        }
                    }
                }

                let changeData = changedStr.data(using: .utf8)!
                data[range.start..<range.end] = changeData

                let offset = changeData.count - (range.end - range.start)
                for (i, changeRange) in lineRangeArr.enumerated() {
                    var changeRange = changeRange as! PDFAnalyze.Range
                    changeRange.start += offset
                    changeRange.end += offset
                    lineRangeArr[i] = changeRange
                }
            }
        }
    }

    func readColor() -> [PDFAnalyze.Range] {
        var lineRanges: [PDFAnalyze.Range] = []
        var startIndex = 0
        for (i, char) in data.enumerated() {
            if char == Character("[").asciiValue! {
                startIndex = i
            }
            if char  == Character("]").asciiValue! {
                lineRanges.append(PDFAnalyze.Range(start: startIndex, end: i + 1))
            }
        }
        return lineRanges
    }
}
