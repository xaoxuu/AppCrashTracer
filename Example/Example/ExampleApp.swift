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
                    AppCrashRecorder.configHeader { jsonHeader in
                        jsonHeader["jsonHeader"] = "这是json文件的header"
                    } fileHeader: { fileHeader in
                        fileHeader["fileHeader"] = "这是崩溃日志文件的header"
                    }
                }
        }
    }
}
