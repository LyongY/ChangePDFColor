//
//  ContentView.swift
//  ChangePDFColor
//
//  Created by YuanLiYong on 2022/9/6.
//

import SwiftUI

struct ContentView: View {
    @State var inDir: String = "/Users/yly/Documents/Programs/GITPrograms/iOS/Programs/SmartCamView/SmartCam View/Launch/Assets.xcassets"
    @State var outDir: String = "/Users/yly/Desktop/NapCat图标"
    @State var dragInFilePath: String = ""

    @State var pdfColors: [RGB2RGB] = [
        RGB2RGB(RGB(114, 184, 254), RGB(255, 131, 31), deviation: 3), // 渐变pdf 浅
        RGB2RGB(RGB(78, 126, 255), RGB(235, 96, 0), deviation: 3), // 渐变pdf 深
        RGB2RGB(RGB(95, 154, 255), RGB(235, 97, 0), deviation: 3), // user 嘴
        RGB2RGB(RGB(67, 128, 235), RGB(235, 97, 0), deviation: 3), // 非渐变pdf
    ]

    @State var pngColors: [RGB2RGB] = [
        RGB2RGB(RGB(67, 128, 235), RGB(235, 97, 0), deviation: 0.05), // 主题色
    ]

    @State var dragInFileColors: [RGB] = []

    var body: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 0) {
                DirectoryView(title: "拖入输入文件夹", dirPath: $inDir)
                DirectoryView(title: "拖入输出文件夹", dirPath: $outDir)
            }

            List {
                Section("pdf 颜色转换列表") {
                    ForEach(pdfColors) { item in
                        ConvertColorView(item, deviationDescrebe: "误差(0~255)") { model in
                            pdfColors = pdfColors.filter { $0 !== model }
                        }
                    }
                    HStack {
                        Spacer()
                        Button("添加新颜色") {
                            pdfColors.append(RGB2RGB(RGB(0, 0, 0), RGB(0, 0, 0), deviation: 1))
                        }
                        Spacer()
                    }
                }

                Section("png 颜色转换列表") {
                    ForEach(pngColors) { item in
                        ConvertColorView(item, deviationDescrebe: "误差(0.0~1.0)") { model in
                            pngColors = pngColors.filter { $0 !== model }
                        }
                    }
                    HStack {
                        Spacer()
                        Button("添加新颜色") {
                            pngColors.append(RGB2RGB(RGB(0, 0, 0), RGB(0, 0, 0), deviation: 0.05))
                        }
                        Spacer()
                    }
                }
            }

            HStack {
                ZStack {
                    VStack {
                        Text("拖入 pdf 或 png 文件")
                        if dragInFilePath.isPdf {
                            PDFViewRepresentable(path: dragInFilePath)
                        } else if dragInFilePath.isPng {
                            AsyncImage(url: URL(fileURLWithPath: dragInFilePath)){ phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable()
                                        .aspectRatio(contentMode: .fit)
                                default:
                                    Spacer()
                                }
                            }
                        }
                    }
                    DragableView { path in
                        path.isPdf || path.isPng
                    } dragIn: { path in
                        dragInFilePath = path
                        if path.isPdf {
                            let pdf = PDFAnalyze(src: path)
                            dragInFileColors = pdf.colors
                        } else if path.isPng {
                            let png = PNGAnalyze(src: path)
                            dragInFileColors = png.colors
                        }
                    }
                }
                List {
                    ForEach(dragInFileColors) { color in
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
                            Text(color.hexString + "  " + color.hueString).font(.system(size: 13).monospaced())
                            Button {
                                if dragInFilePath.isPdf {
                                    pdfColors.append(
                                        RGB2RGB(color.clone(), color.clone(), deviation: 1)
                                    )
                                } else if dragInFilePath.isPng {
                                    pngColors.append(
                                        RGB2RGB(color.clone(), color.clone(), deviation: 0.05)
                                    )
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            HStack {
                Button("开始转换") {
                    _ = ChangeColor.dir(in: inDir, out: outDir, pdfColors: pdfColors, pngColors: pngColors)
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

    let deviationDescrebe: String
    var deleteClick: (RGB2RGB) -> Void

    init(_ model: RGB2RGB, deviationDescrebe: String, deleteClick: @escaping (_ model: RGB2RGB) -> Void) {
        self.model = model
        self.deviationDescrebe = deviationDescrebe
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

            Text(deviationDescrebe)
            TextField("", text: $deviation)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 50)
                .onChange(of: deviation) { newValue in
                    if let deviation = Double(newValue) {
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
            pdfColors: [
                RGB2RGB(RGB(114, 184, 254), RGB(255, 0, 0), deviation: 3),
                RGB2RGB(RGB(78, 126, 255), RGB(0, 255, 0), deviation: 3),
                RGB2RGB(RGB(67, 128, 235), RGB(0, 0, 255), deviation: 3),
            ],
            pngColors: [
                RGB2RGB(RGB(114, 184, 254), RGB(255, 0, 0), deviation: 3),
                RGB2RGB(RGB(78, 126, 255), RGB(0, 255, 0), deviation: 3),
                RGB2RGB(RGB(67, 128, 235), RGB(0, 0, 255), deviation: 3),
            ],
            dragInFileColors: [RGB(67, 128, 235), RGB(0, 222, 230)]
        )
    }
}
