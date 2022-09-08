//
//  ChangeColor.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/6.
//

import Foundation
import Kanna
import Macaw

enum ChangeColor {
    static func dir(in: String, out: String, colors: [RGB2RGB]) -> Bool {
        guard isDir(`in`), isDir(out) else { return false }

        let fileManager = FileManager.default
        guard var pathArr = fileManager.subpaths(atPath: `in`) else { return false }
        pathArr = pathArr.map {
            URL(fileURLWithPath: `in` + "/" + $0)
        }.filter {
            $0.pathExtension == "pdf"
        }.map {
            $0.path
        }

        for inPath in pathArr {
            let inURL = URL(fileURLWithPath: inPath)
            var outURL = URL(fileURLWithPath: out)
            outURL.appendPathComponent(inURL.lastPathComponent)
            outURL = URL(fileURLWithPath: outURL.path.replacingOccurrences(of: ".pdf", with: ".png")) // 转成png
            guard path(in: inPath, out: outURL.path, colors: colors) else {
                return false
            }
        }
        return true
    }

    private static func isDir(_ path: String) -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

    static func path(in: String, out: String, colors: [RGB2RGB]) -> Bool {
        let inURL = URL(fileURLWithPath: `in`)
        let pathExtension = inURL.pathExtension
        let tempFilePath = `in`.replacingOccurrences(of: ".\(pathExtension)", with: "") + "justtemp.svg"

        defer {
            try? FileManager.default.removeItem(atPath: tempFilePath)
        }

        guard convert(pdfPath: `in`, toSvgPath: tempFilePath) else {
            return false
        }
        guard optimizationLinearGradient(with: tempFilePath) else {
            return false
        }
        guard change(svg: tempFilePath, colors: colors) else {
            return false
        }
        guard convert(svgPath: tempFilePath, toPdfPath: out) else {
            return false
        }
        return true
    }

    private static func convert(pdfPath: String, toSvgPath: String) -> Bool {
        let pipe = Pipe()
        let process = Process()
        process.launchPath = "/usr/local/bin/inkscape"
//        process.arguments = ["--export-plain-svg", "--export-filename=\(toSvgPath)", "--pdf-poppler", pdfPath]
        process.arguments = ["--export-filename=\(toSvgPath)", "--pdf-poppler", pdfPath]
        process.standardOutput = pipe
        process.launch()

        process.waitUntilExit()

        return process.terminationStatus == 0
    }

    private static func optimizationLinearGradient(with svgPath: String) -> Bool {
        let doc = try! Kanna.XML(url: .init(fileURLWithPath: svgPath), encoding: .utf8)
        let linearGradients = doc.xpath("//*[name()='svg']//*[name()='linearGradient']//*[name()='stop']")
        if linearGradients.count > 2 {

        }
        let removeArr = linearGradients.filter { element in
            element.previousSibling != nil && element.nextSibling != nil
        }
        removeArr.forEach { element in
            element.parent?.removeChild(element)
        }
        guard let xmlStr = doc.toXML else {
            return false
        }
        try! xmlStr.write(toFile: svgPath, atomically: true, encoding: .utf8)
        return true
    }

    private static func change(svg: String, colors: [RGB2RGB]) -> Bool {
        guard var fileStr = try? String(contentsOfFile: svg, encoding: .utf8) else {
            return false
        }
        let pattern = "rgb\\(\\d+.\\d+%, \\d+.\\d+%, \\d+.\\d+%\\)"
        let regex = try! NSRegularExpression(pattern: pattern, options:[])
        let matches = regex.matches(in: fileStr, options: [], range: NSRange(fileStr.startIndex...,in: fileStr))

        var searchResultArr: [String] = []
        for match in matches {
            let oriString = String(fileStr[Range(match.range, in: fileStr)!])
            searchResultArr.append(oriString)
        }

        for currentString in searchResultArr {
            for rgb2rgb in colors {
                let arr = currentString.replacingOccurrences(of: "rgb(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "%", with: "").components(separatedBy: ", ")

                let currentColor = RGB(
                    r: Int(Double(arr[0])! / 100 * 255),
                    g: Int(Double(arr[1])! / 100 * 255),
                    b: Int(Double(arr[2])! / 100 * 255)
                )

                if currentColor.like(rgb2rgb.oriRGB, deviation: 5) {
                    fileStr = fileStr.replacingOccurrences(of: currentString, with: rgb2rgb.toRGB.toSVGSearchString())
                }
            }
        }

        try! fileStr.write(toFile: svg, atomically: true, encoding: .utf8)

        return true
    }

    private static func convert(svgPath: String, toPdfPath: String) -> Bool {

//        let svgView = SVGView(frame: .init(x: 0, y: 0, width: 80, height: 80))
//        svgView.fileName = svgPath
//        svgView.toPDF(size: .init(width: 80, height: 80), path: .init(fileURLWithPath: toPdfPath))


//        guard let node = try? SVGParser.parse(fullPath: svgPath) else { return false }
//
//        let view = SVGView(node: node, frame: .init(x: 0, y: 0, width: 80, height: 80))
//        view.toPDF(size: .init(width: 80, height: 80), path: .init(fileURLWithPath: toPdfPath))
//
//        return true

        let pipe = Pipe()
        let process = Process()
        process.launchPath = "/usr/local/bin/inkscape"
//        process.arguments = ["--export-filename=\(toPdfPath)", "--export-dpi=36", svgPath]
//        process.arguments = ["--export-filename=\(toPdfPath)", "--export-dpi=72", svgPath]
        process.arguments = ["--export-filename=\(toPdfPath)", "--export-dpi=108", svgPath]
        process.standardOutput = pipe
        process.launch()

        process.waitUntilExit()

        return process.terminationStatus == 0
    }

    static func colorsWith(pdfPath: String) -> [RGB] {
        let inURL = URL(fileURLWithPath: pdfPath)
        let pathExtension = inURL.pathExtension
        let tempFilePath = pdfPath.replacingOccurrences(of: ".\(pathExtension)", with: "") + "justtempforSearchColor.svg"

        defer {
            try? FileManager.default.removeItem(atPath: tempFilePath)
        }
        
        guard convert(pdfPath: pdfPath, toSvgPath: tempFilePath) else {
            return []
        }
        guard optimizationLinearGradient(with: tempFilePath) else {
            return []
        }

        guard let fileStr = try? String(contentsOfFile: tempFilePath, encoding: .utf8) else {
            return []
        }
        let pattern = "rgb\\(\\d+.\\d+%, \\d+.\\d+%, \\d+.\\d+%\\)"
        let regex = try! NSRegularExpression(pattern: pattern, options:[])
        let matches = regex.matches(in: fileStr, options: [], range: NSRange(fileStr.startIndex...,in: fileStr))

        var searchResultArr: [String] = []
        for match in matches {
            let oriString = String(fileStr[Range(match.range, in: fileStr)!])
            searchResultArr.append(oriString)
        }

        return searchResultArr.map { currentString in
            let arr = currentString.replacingOccurrences(of: "rgb(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "%", with: "").components(separatedBy: ", ")
            return RGB(
                r: Int(Double(arr[0])! / 100 * 255),
                g: Int(Double(arr[1])! / 100 * 255),
                b: Int(Double(arr[2])! / 100 * 255)
            )
        }
    }
}
