//
//  ChangeColor.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/6.
//

import Foundation

enum ChangeColor {
    static func dir(in: String, out: String, pdfColors: [RGB2RGB], pngColors: [RGB2RGB]) -> Bool {
        let startDate = Date()
        defer {
            print("总共耗时: \(Date().timeIntervalSince(startDate))秒")
        }

        guard isDir(`in`), isDir(out) else { return false }
        guard `in`.count > 15, out.count > 15 else { return false } // 防止遍历 root 文件夹

        let fileManager = FileManager.default
        guard var pathArr = fileManager.subpaths(atPath: `in`) else { return false }
        pathArr = pathArr.map {
            URL(fileURLWithPath: `in` + "/" + $0)
        }.filter {
            $0.path.isPdf || $0.path.isPng
        }.map {
            $0.path
        }

        let hueFilter = PNGAnalyze.filter(with: pngColors)

        let semaphore = DispatchSemaphore(value: 0)
        let queue = OperationQueue()
        for inPath in pathArr {
            let operation = BlockOperation {
                autoreleasepool {
                    let inURL = URL(fileURLWithPath: inPath)
                    var outURL = URL(fileURLWithPath: out)
                    outURL.appendPathComponent(inURL.lastPathComponent)

                    if inURL.path.isPdf {
                        let pdf = PDFAnalyze(src: inPath)
                        pdf.change(colors: pdfColors)
                        pdf.export(to: outURL.path)
                    } else if inURL.path.isPng {
                        let png = PNGAnalyze(src: inPath)
                        png.changeColor(with: hueFilter)
                        png.export(to: outURL.path)
                    }
                }
                semaphore.signal()
            }
            queue.addOperation(operation)
            semaphore.wait()
        }
        return true
    }

    private static func isDir(_ path: String) -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

}
