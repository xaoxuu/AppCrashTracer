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
                }
        }
    }
}
