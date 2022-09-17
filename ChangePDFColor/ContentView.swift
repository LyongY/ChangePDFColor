//
//  ContentView.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/6.
//

import SwiftUI

class UserData {
    static let `default` = UserData()
    private init() { }
    var exportType = "pdf"
    var dpi = 72
    var inkscapePath = "/Applications/Inkscape.app"
}

struct ContentView: View {
    @State var inkscapePath = UserData.default.inkscapePath
    @State var inDir: String = ""
    @State var outDir: String = ""
    @State var pdfPath: String = ""

    @State var exportType = UserData.default.exportType
    @State var dpi = UserData.default.dpi
    
    @State var colors: [RGB2RGB] = [
        RGB2RGB(RGB(114, 184, 254), RGB(88, 0, 0), deviation: 3),
        RGB2RGB(RGB(78, 126, 255), RGB(0, 88, 0), deviation: 3),
        RGB2RGB(RGB(67, 128, 235), RGB(0, 0, 88), deviation: 3)
    ]

    @State var pdfColors: [RGB] = []

    var body: some View {
        VStack(alignment: .leading) {

            VStack(spacing: 0) {
                DirectoryView(title: "拖入 Inkscape app", dirPath: $inkscapePath)
                    .onChange(of: inkscapePath) { newValue in
                        UserData.default.inkscapePath = newValue
                    }
                DirectoryView(title: "拖入输入文件夹", dirPath: $inDir)
                DirectoryView(title: "拖入输出文件夹", dirPath: $outDir)
            }

            Picker("导出为", selection: $exportType) {
                Text("png").tag("png")
                Text("pdf").tag("pdf")
            }.onChange(of: exportType) { newValue in
                UserData.default.exportType = newValue
            }

            Picker("屏幕为", selection: $dpi) {
                Text("@1x").tag(36)
                Text("@2x").tag(72)
                Text("@3x").tag(108)
            }.onChange(of: dpi) { newValue in
                UserData.default.dpi = newValue
            }


            List {
                Section("颜色转换列表") {
                    ForEach(colors) { item in
                        ConvertColorView(item) { model in
                            colors = colors.filter { $0 !== model }
                        }
                    }
                    HStack {
                        Spacer()
                        Button("添加新颜色") {
                            colors.append(RGB2RGB(RGB(0, 0, 0), RGB(0, 0, 0), deviation: 0))
                        }
                        Spacer()
                    }
                }
            }

            HStack {
                ZStack {
                    VStack {
                        Text("拖入pdf文件")
                        PDFViewRepresentable(path: pdfPath)
                    }
                    DragableView { path in
                        URL(fileURLWithPath: path).pathExtension == "pdf"
                    } dragIn: { path in
                        pdfPath = path
                        let pdf = PDFAnalyze(src: path)
                        pdfColors = pdf.colors
                    }
                }
                List {
                    ForEach(pdfColors) { color in
                        HStack {
                            Rectangle().fill(
                                Color(
                                    .sRGB,
                                    red: Double(color.r) / 255,
                                    green: Double(color.g) / 255,
                                    blue: Double(color.b) / 255,
                                    opacity: 1
                                )
                            ).frame(maxWidth: 36, maxHeight: 36)
                            Text(color.hexString).font(.system(size: 13).monospaced())
                            Button {
                                colors.append(
                                    RGB2RGB(color.clone(), color.clone(), deviation: 1)
                                )
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                Button("开始转换") {
                    _ = ChangeColor.dir(in: inDir, out: outDir, colors: colors)
                }
            }

        }.padding()
            .frame(minWidth: 700, minHeight: 800)
    }
}

struct DirectoryView: View {
    let title: String
    @Binding var dirPath: String
    var body: some View {
        ZStack {
            DragableView(dragDirectoryIn: { path in
                self.dirPath = path
            }).frame(maxHeight: 36)
            HStack {
                Text(title).padding()
                Text(dirPath)
                Spacer()
            }.frame(maxHeight: 36)
        }
    }
}

struct ConvertColorView: View {
    var model: RGB2RGB
    @ObservedObject var oriRGB: RGB
    @ObservedObject var toRGB: RGB

    @State var oriHex: String
    @State var toHex: String
    @State var deviation: String

    var deleteClick: (RGB2RGB) -> Void

    init(_ model: RGB2RGB, deleteClick: @escaping (_ model: RGB2RGB) -> Void) {
        self.model = model
        self.deleteClick = deleteClick
        oriRGB = model.oriRGB
        toRGB = model.toRGB
        oriHex = model.oriRGB.hexString
        toHex = model.toRGB.hexString
        deviation = "\(model.deviation)"
    }

    var body: some View {
        HStack {
            Rectangle().fill(
                Color(
                    .sRGB,
                    red: Double(oriRGB.r) / 255,
                    green: Double(oriRGB.g) / 255,
                    blue: Double(oriRGB.b) / 255,
                    opacity: 1
                )
            ).frame(maxWidth: 36, maxHeight: 36)
            Text("->")
            Rectangle().fill(
                Color(
                    .sRGB,
                    red: Double(toRGB.r) / 255,
                    green: Double(toRGB.g) / 255,
                    blue: Double(toRGB.b) / 255,
                    opacity: 1
                )
            ).frame(maxWidth: 36, maxHeight: 36)

            Text("误差")
            TextField("", text: $deviation)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 36)
                .onChange(of: deviation) { newValue in
                    if let deviation = Int(newValue) {
                        model.deviation = deviation
                    }
                }

            Text("|||")

            TextField("", text: $oriHex)
                .textFieldStyle(.roundedBorder)
                .onChange(of: oriHex) { newValue in
                    oriRGB.hexString = newValue
                }
            Text("->")
            TextField("", text: $toHex)
                .textFieldStyle(.roundedBorder)
                .onChange(of: toHex) { newValue in
                    toRGB.hexString = newValue
                }

            Button {
                deleteClick(model)
            } label: {
                Image(systemName: "xmark.circle.fill")
            }.buttonStyle(.plain)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            colors: [
                RGB2RGB(RGB(114, 184, 254), RGB(255, 0, 0), deviation: 3),
                RGB2RGB(RGB(78, 126, 255), RGB(0, 255, 0), deviation: 3),
                RGB2RGB(RGB(67, 128, 235), RGB(0, 0, 255), deviation: 3),
            ],
            pdfColors: [RGB(67, 128, 235), RGB(0, 222, 230)]
        )
    }
}
