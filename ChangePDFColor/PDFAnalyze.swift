//
//  PDFAnalyze.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/9.
//

import Foundation

class PDFAnalyze {
    var notStreamDataArr: [PDFNotStream] = []
    var streamDataArr: [PDFStream] = []

    init(src: String) {
        let data = try! Data(contentsOf: URL(fileURLWithPath: src))

        var currentData = Data()
        for char in data {
            currentData.append(char)

            if currentData.suffix(9) == "endstream".data(using: .utf8)! {
                let streamData = currentData[0..<currentData.count - 9]
                streamDataArr.append(PDFStream(streamData))
                currentData = "endstream".data(using: .utf8)!
                continue
            }

            if currentData.suffix(6) == "stream".data(using: .utf8)!, currentData.suffix(9) != "endstream".data(using: .utf8)! {
                notStreamDataArr.append(PDFNotStream(currentData))
                currentData = Data()
                continue
            }
        }
        notStreamDataArr.append(PDFNotStream(currentData))
    }

    var colors: [RGB] {
        var colorArr: [RGB] = []

        // 搜索明文
        for notStream in notStreamDataArr {
            for rgb in notStream.colors {
                if !colorArr.contains(rgb) {
                    colorArr.append(rgb)
                }
            }
        }

        // 搜索流
        for stream in streamDataArr {
            for rgb in stream.colors {
                if !colorArr.contains(rgb) {
                    colorArr.append(rgb)
                }
            }
        }
        return colorArr
    }

    func change(colors: [RGB2RGB]) {
        // 修改明文
        for notStream in notStreamDataArr {
            notStream.change(colors: colors)
        }

        // 修改索流
        for stream in streamDataArr {
            stream.change(colors: colors)
        }
    }

    func export(to path: String) {
        var outData = Data()
        for i in 0..<notStreamDataArr.count {
            outData += notStreamDataArr[i].data
            if i < streamDataArr.count {
                outData += streamDataArr[i].data
            }
        }
        try! outData.write(to: URL(fileURLWithPath: path))
    }
}

extension PDFAnalyze {
    struct Range {
        var start: Int
        var end: Int
    }

    static func string(_ data: Data, with lineRange: PDFAnalyze.Range) -> String? {
        let lineData = data[lineRange.start..<lineRange.end]
        let str = String(data: lineData, encoding: .utf8)
        return str
    }

}
