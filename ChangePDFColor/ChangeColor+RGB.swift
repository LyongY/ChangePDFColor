//
//  ChangeColor+RGB.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/6.
//

import Foundation
import SwiftUI

class RGB2RGB: Identifiable {
    let id = UUID()
    let oriRGB: RGB
    let toRGB: RGB

    var deviation: Int

    init(_ oriRGB: RGB, _ toRGB: RGB, deviation: Int) {
        self.oriRGB = oriRGB
        self.toRGB = toRGB
        self.deviation = deviation
    }

    func rgbDescribe() -> String {
        "\(oriRGB.r),\(oriRGB.g),\(oriRGB.b)-->\(toRGB.r),\(toRGB.g),\(toRGB.b)"
    }

    func hexDescribe() -> String {
        "#\(String(format: "%02x", oriRGB.r))\(String(format: "%02x", oriRGB.g))\(String(format: "%02x", oriRGB.b))-->#\(String(format: "%02x", toRGB.r))\(String(format: "%02x", toRGB.g))\(String(format: "%02x", toRGB.b))"
    }
}

class RGB: ObservableObject, Identifiable, Equatable {
    static func == (lhs: RGB, rhs: RGB) -> Bool {
        lhs.r == rhs.r && lhs.g == rhs.g && lhs.b == rhs.b
    }

    let id = UUID()
    @Published var r: Int
    @Published var g: Int
    @Published var b: Int

    init(_ r: Int, _ g: Int, _ b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(r: Int, g: Int, b: Int) {
        self.r = r
        self.g = g
        self.b = b
    }

    func clone() -> RGB {
        RGB(r, g, b)
    }

    func like(_ color: RGB, deviation: Int) -> Bool {
        if
            r >= color.r - deviation, r <= color.r + deviation,
            g >= color.g - deviation, g <= color.g + deviation,
            b >= color.b - deviation, b <= color.b + deviation
        {
            return true
        }
        return false
    }

    func toSVGSearchString() -> String {
        let fR = Double(r) / 255 * 100
        let fG = Double(g) / 255 * 100
        let fB = Double(b) / 255 * 100
        return "rgb(\(fR)%, \(fG)%, \(fB)%)"
    }

    var hexString: String {
        get {
            "#\(String(format: "%02x", r))\(String(format: "%02x", g))\(String(format: "%02x", b))"
        }
        set {
            let string = newValue.replacingOccurrences(of: "#", with: "") as NSString
            var hR: UInt64 = 0
            var hG: UInt64 = 0
            var hB: UInt64 = 0

            if string.length >= 6,
               Scanner(string: string.substring(to: 2)).scanHexInt64(&hR),
               Scanner(string: string.substring(with: .init(location: 2, length: 2))).scanHexInt64(&hG),
               Scanner(string: string.substring(with: .init(location: 4, length: 2))).scanHexInt64(&hB)
            {
                r = Int(hR)
                g = Int(hG)
                b = Int(hB)
            } else {
                r = 0
                g = 0
                b = 0
            }
        }
    }
}
