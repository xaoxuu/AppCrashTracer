//
//  CrashTracer.swift
//  CrashTracerDemo
//
//  Created by xaoxuu on 2022/4/22.
//

import UIKit

/// App异常事件手动追踪器
/// 在任何地方调用trace手动记录关键轨迹，崩溃时将这些轨迹记录到崩溃日志中
@objc public class AppCrashTracer: NSObject {
    
    @objc public static var userInfo = [String: Any]()
    
}


public extension AppCrashTracer {

    /// 初始化
    /// - Parameter folder: 日志文件夹名称
    @objc static func start(folder: String? = nil) {
        // config recorder
        Recorder.prepare(folder: folder)
        // config exception callback
        Caughter.onException { Recorder.record(exception: $0) }
    }
    
}
