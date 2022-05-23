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
                    AppCrashRecorder.configCustomInfo { jsonHeader, fileHeader, userInfo in
                        jsonHeader["jsonHeader"] = "这是json文件的header"
                        fileHeader["fileHeader"] = "这是崩溃日志文件的header"
                        userInfo["page"] = "live"
                        userInfo["pages"] = "main, live"
                    }
                }
        }
    }
}
