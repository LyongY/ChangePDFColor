//
//  PDFAnalyze.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/9.
//

import Foundation

class PDFAnalyze {
    var headData = Data()
    var splitDataArr: [Data] = []
    var streamDataArr: [Data] = []

    var splitStringArr: [String] = [] {
        didSet {
            splitDataArr = splitStringArr.map({ str in
                str.data(using: .utf8)!
            })
            print(splitDataArr)
        }
    }
    var streamStringArr: [String] = [] {
        didSet {
            streamDataArr = streamStringArr.map({ str in
                (str.data(using: .utf8)! as NSData).zipped()
            })
        }
    }

    init(src: String) {
        let stream = "stream\n"
        let endstream = "endstream\n"
        let data = try! Data(contentsOf: URL(fileURLWithPath: src))
        var lineData = Data()

        var currentData = Data()
        var lineIndex = 0
        for char in data {
            lineData.append(char)
            if lineIndex < 2 {
                headData.append(char)
            } else {
                currentData.append(char)
            }
            if char == 0x0a { // 换行
                if let line = String(data: lineData, encoding: .utf8) {
                    if line == stream {
                        splitDataArr.append(currentData)
                        currentData = Data()
                    }
                    if line == endstream {
                        let endstreamStringData = ("\n" + endstream).data(using: .utf8)!
                        streamDataArr.append(currentData[0..<currentData.count - endstreamStringData.count])
                        currentData = endstreamStringData
                    }
                }
                lineData = Data()
                lineIndex += 1
            }
        }
        splitDataArr.append(currentData)

        splitStringArr = splitDataArr.map({ data in
            String(data: data, encoding: .utf8)!
        })

        streamStringArr = streamDataArr.map({ zippedData in
            let decodeData = (zippedData as NSData).unzipped()
            let plain = String(data: decodeData, encoding: .utf8)!
            return plain
        })
    }

    var colors: [RGB] {
        var colorArr: [RGB] = []

        // 搜索明文
        for str in splitStringArr {
            // 匹配 [0.111 0.2222 0.3333] 格式
            let pattern = "\\[((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+))\\]"
            let regex = try! NSRegularExpression(pattern: pattern, options:[])
            let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex...,in: str))

            for match in matches {
                var oriString = String(str[Range(match.range, in: str)!])
                oriString = oriString.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
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

        // 搜索流
        for str in streamStringArr {
            let pattern = "((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) scn"
            let regex = try! NSRegularExpression(pattern: pattern, options:[.caseInsensitive])
            let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex...,in: str))

            for match in matches {
                let oriString = String(str[Range(match.range, in: str)!])
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
        return colorArr
    }

    func change(colors: [RGB2RGB]) {
        // 修改明文
        for (i, str) in splitStringArr.enumerated() {
            // 匹配 [0.111 0.2222 0.3333] 格式
            let pattern = "\\[((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+))\\]"
            let regex = try! NSRegularExpression(pattern: pattern, options:[])
            let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex...,in: str))

            var changedStr = str
            for match in matches {
                var oriString = String(str[Range(match.range, in: str)!])
                oriString = oriString.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
                let arr = oriString.components(separatedBy: " ")
                let rgb = RGB(
                    r: Int(Double(arr[0])! * 255),
                    g: Int(Double(arr[1])! * 255),
                    b: Int(Double(arr[2])! * 255)
                )

                for colorTouple in colors {
                    if colorTouple.oriRGB.like(rgb, deviation: colorTouple.deviation) {
                        let rString = String(format: "%.6g", Double(colorTouple.toRGB.r) / 255)
                        let gString = String(format: "%.6g", Double(colorTouple.toRGB.g) / 255)
                        let bString = String(format: "%.6g", Double(colorTouple.toRGB.b) / 255)
                        changedStr = changedStr.replacingOccurrences(of: "[\(oriString)]", with: "[\(rString) \(gString) \(bString)]")
                        splitStringArr[i] = changedStr
                    }
                }
            }
        }

        // 修改索流
        for (i, str) in streamStringArr.enumerated() {
            let pattern = "((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) ((0)|(1)|(0\\.\\d+)|(1\\.0+)) scn"
            let regex = try! NSRegularExpression(pattern: pattern, options:[.caseInsensitive])
            let matches = regex.matches(in: str, options: [], range: NSRange(str.startIndex...,in: str))

            var changedStr = str
            for match in matches {
                let oriString = String(str[Range(match.range, in: str)!])
                let arr = oriString.components(separatedBy: " ")
                let rgb = RGB(
                    r: Int(Double(arr[0])! * 255),
                    g: Int(Double(arr[1])! * 255),
                    b: Int(Double(arr[2])! * 255)
                )

                let lastString = arr[3]

                for colorTouple in colors {
                    if colorTouple.oriRGB.like(rgb, deviation: colorTouple.deviation) {
                        let rString = String(format: "%.6g", Double(colorTouple.toRGB.r) / 255)
                        let gString = String(format: "%.6g", Double(colorTouple.toRGB.g) / 255)
                        let bString = String(format: "%.6g", Double(colorTouple.toRGB.b) / 255)
                        changedStr = changedStr.replacingOccurrences(of: oriString, with: "\(rString) \(gString) \(bString) \(lastString)")
                        streamStringArr[i] = changedStr
                    }
                }
            }
        }
    }

    func export(to path: String) {
        var outData = headData
        for i in 0..<splitDataArr.count {
            outData += splitDataArr[i]
            if i < streamDataArr.count {
                outData += streamDataArr[i]
            }
        }
        try! outData.write(to: URL(fileURLWithPath: path))
    }
}
