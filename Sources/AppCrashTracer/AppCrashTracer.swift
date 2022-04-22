//
//  CrashTracer.swift
//  CrashTracerDemo
//
//  Created by xaoxuu on 2022/4/22.
//

import UIKit

/// App异常事件手动追踪器
/// 在任何地方调用trace手动记录关键轨迹，崩溃时将这些轨迹记录到崩溃日志中
public class AppCrashTracer: NSObject {
    
}


public extension AppCrashTracer {

    /// 初始化
    /// - Parameter folder: 日志文件夹名称
    @objc static func start(folder: String? = nil) {
        if let folder = folder {
            Recorder.folderName = folder
        }
        if let folderDir = Recorder.workspace {
            if FileManager.default.fileExists(atPath: folderDir.path) == false {
                try? FileManager.default.createDirectory(atPath: folderDir.path, withIntermediateDirectories: true)
            }
        }
        // on exception
        Caughter.onException { Recorder.onCrash(exception: $0) }
        
    }
    
}
