//
//  ExampleApp.swift
//  Example
//
//  Created by xaoxuu on 2022/4/22.
//

import SwiftUI
import AppCrashTracer

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AppCrashTracer.start()
                    AppCrashRecorder.configJsonFileHeader { header in
                        header["jsonHeader"] = "这是json文件的header"
                    }
                    AppCrashRecorder.configLogFileHeader { header in
                        header["fileHeader"] = "这是崩溃日志文件的header"
                    }
                }
        }
    }
}
