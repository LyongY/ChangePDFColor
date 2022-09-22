//
//  PNGAnalyze.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/20.
//

import AppKit
import CoreImage

class PNGAnalyze {
    var imageRep: NSBitmapImageRep
    var ciImage: CIImage
    let colorSpace: NSColorSpace
    init(src: String) {
        guard let image = NSImage(contentsOfFile: src), let data = image.tiffRepresentation, let imageRep = NSBitmapImageRep(data: data), let ciImage = CIImage(bitmapImageRep: imageRep) else {
            fatalError()
        }
        colorSpace = imageRep.colorSpace
        self.ciImage = ciImage
        self.imageRep = imageRep
    }

    var colors: [RGB] {
        var hueArr: [Int] = []
        let width = Int(imageRep.size.width)
        let height = Int(imageRep.size.height)
        for i in 0..<width {
            for j in 0..<height {
                if let color = imageRep.colorAt(x: i, y: j) {
                    let currentHue = Int(color.hueComponent * 100)
                    if !hueArr.contains(currentHue) {
                        hueArr.append(currentHue)
                    }
                }
            }
        }

        let colorArr = hueArr.sorted(by: <).map { hue in
            NSColor(hue: CGFloat(hue) / 100, saturation: 1, brightness: 1, alpha: 1)
        }

        let rgbArr = colorArr.map { color in
            RGB(
                r: Int(color.redComponent * 255),
                g: Int(color.greenComponent * 255),
                b: Int(color.blueComponent * 255)
            )
        }
        return rgbArr
    }

    func change(colors: [RGB2RGB]) {
        let width = Int(imageRep.size.width)
        let height = Int(imageRep.size.height)
        for i in 0..<width {
            for j in 0..<height {
                if let color = imageRep.colorAt(x: i, y: j)?.usingColorSpace(.genericRGB) {
                    let currentHue = color.hueComponent
                    for rgb2rgb in colors {
                        let orihue = rgb2rgb.oriRGB.hue
                        let deviation = rgb2rgb.deviation
                        if abs(currentHue - orihue) < deviation {
                            let sat = color.saturationComponent
                            let bri = color.brightnessComponent
                            let alpha = color.alphaComponent

                            let toHue = rgb2rgb.toRGB.hue
                            let toColor = NSColor(calibratedHue: toHue, saturation: sat, brightness: bri, alpha: alpha)
                            self.imageRep.setColor(toColor, atX: i, y: j)
                        }
                    }
                }
            }
        }
    }

    func changeColor(with filter: CIFilter) {
        filter.setValue(ciImage, forKey: "inputImage")
        ciImage = filter.outputImage!
        imageRep = NSBitmapImageRep(ciImage: ciImage)
    }

    func export(to path: String) {
        let toData = imageRep.representation(using: .png, properties: [.compressionFactor: 0])
        try? toData?.write(to: URL(fileURLWithPath: path))
    }

    static func filter(with colors: [RGB2RGB]) -> CIFilter {
        let date = Date()
        defer {
            print("创建 lookup table 耗时: \(Date().timeIntervalSince(date))")
        }

        let size = 128
        var filterData = [Float].init(repeating: 1, count: size * size * size * 4)
        for b in 0..<size {
            for g in 0..<size {
                for r in 0..<size {
                    let color = NSColor(calibratedRed: CGFloat(r) / CGFloat(size - 1), green: CGFloat(g) / CGFloat(size - 1), blue: CGFloat(b) / CGFloat(size - 1), alpha: 1)
                    for rgb2rgb in colors {
                        var toR = Float(r) / Float(size - 1)
                        var toG = Float(g) / Float(size - 1)
                        var toB = Float(b) / Float(size - 1)
                        if abs(color.hueComponent - rgb2rgb.oriRGB.hue) < rgb2rgb.deviation {
                            let toHue = rgb2rgb.toRGB.hue
                            let toColor = NSColor(calibratedHue: toHue, saturation: color.saturationComponent, brightness: color.brightnessComponent, alpha: 1)
                            toR = Float(toColor.redComponent)
                            toG = Float(toColor.greenComponent)
                            toB = Float(toColor.blueComponent)
                        }
                        let i = (r + g * size + b * size * size) * 4
                        filterData[i] = toR
                        filterData[i + 1] = toG
                        filterData[i + 2] = toB
                    }
                }
            }
        }
        let colorCube = CIFilter(name: "CIColorCubeWithColorSpace", parameters: [
            "inputCubeDimension": size,
            "inputCubeData": Data(buffer: UnsafeBufferPointer(start: &filterData, count: filterData.count)) as NSData,
            "inputColorSpace": NSColorSpace.sRGB.cgColorSpace!
        ])!
        return colorCube
    }
}
