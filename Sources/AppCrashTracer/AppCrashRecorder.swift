//
//  AppCrashRecorder.swift
//  
//
//  Created by xaoxuu on 2022/4/22.
//

import UIKit

public extension AppCrashTracer {
    struct Recorder {
        
        public struct Session {
            public let identifier: String
            public static var app: Session { .init("app") }
            public init (_ identifier: String) {
                self.identifier = identifier
            }
        }
        
        /// 自定义记录最大个数
        public static var maxRecordCount = 50
        
        /// 崩溃时是否记录详情，如果有第三方工具同时记录，这个可以设置为false
        public static var configRecordExceptionDetail = true
        
        /// 所有的手动record文本
        public private(set) static var allRecords = [(meta: String, message: String)]()
        
        static var workspace: URL?
        
        static let dateFormatter = DateFormatter()
        
        fileprivate static var launchTime = Date()
        
        /// 崩溃时间，如果未空表示还未崩溃
        static var crashTime: Date?
        
        fileprivate static var configCustomInfoCallback: ((_ jsonHeader: inout [String: Any], _ fileHeader: inout [String: Any], _ userInfo: inout [String: Any]) -> Void)?
        
    }
}

public typealias AppCrashRecorder = AppCrashTracer.Recorder

public extension AppCrashTracer.Recorder {
    
    /// 记录
    /// - Parameters:
    ///   - session: trace session
    static func record(_ session: Session, file: String = #file, function: String = #function, line: Int = #line) {
        let meta = "[\(timeStr(format: "MM-dd HH:mm:ss"))][\(session.identifier)] " + (file as NSString).lastPathComponent + " \(function) <line:\(line)>"
        appendRecord((meta: meta, message: ""))
    }
    
    /// 记录
    /// - Parameters:
    ///   - session: trace session
    ///   - messages: 额外需要记录的内容
    static func record(_ session: Session, _ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
        let meta = "[\(timeStr(format: "MM-dd HH:mm:ss"))][\(session.identifier)] " + (file as NSString).lastPathComponent + " \(function) <line:\(line)>"
        let strArr = items.compactMap {String.init(describing: $0)}
        var message = ""
        if strArr.count > 0 {
            message = "> " + strArr.joined(separator: ", ")
        }
        appendRecord((meta: meta, message: message))
    }
    
    /// 记录
    /// - Parameters:
    ///   - session: trace session
    ///   - code: code信息
    ///   - messages: 额外需要记录的内容
    static func customRecord(_ session: String, code: String, message: String? = nil) {
        appendRecord((meta: "[\(timeStr(format: "MM-dd HH:mm:ss"))][\(session)] " + code, message: message ?? ""))
    }
    
}


public extension AppCrashTracer.Recorder {
    
    /// 导出新增的日志
    static func exportLogFiles() -> [URL] {
        guard let workspace = workspace else {
            return []
        }
        var urls = [URL]()
        if let dirEnum = FileManager.default.enumerator(atPath: workspace.path) {
            var logs = (dirEnum.allObjects as? [String]) ?? [String]()
            logs.sort()
            urls = logs.map { workspace.appendingPathComponent($0) }
        }
        return urls.filter { ["log", "json"].contains($0.pathExtension) }
    }
    
    /// 删除日志
    /// - Parameter fileURL: 日志路径
    static func removeLog(fileURL: URL?) {
        guard let fileURL = fileURL else {
            return
        }
        try? FileManager.default.removeItem(at: fileURL)
    }
    
}


extension AppCrashTracer.Recorder {
    
    /// 配置崩溃日志的header，当崩溃发生时会进入此回调
    /// - Parameter callback: 回调
    public static func configCustomInfo(callback: @escaping (_ jsonHeader: inout [String: Any], _ fileHeader: inout [String: Any], _ userInfo: inout [String: Any]) -> Void) {
        configCustomInfoCallback = callback
    }
    
    static func prepare(folder: String? = nil) {
        launchTime = Date()
        let dir: String
        if let folder = folder, folder.count > 0 {
            dir = folder
        } else {
            dir = "Crashes"
        }
        workspace = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(dir, isDirectory: true)
        if let folderDir = workspace {
            if FileManager.default.fileExists(atPath: folderDir.path) == false {
                try? FileManager.default.createDirectory(atPath: folderDir.path, withIntermediateDirectories: true)
            }
        }
    }
    
    /// 重置数据
    static func reset() {
        crashTime = nil
    }
    
    static func recordException(name: String?, reason: String?, description: String?) {
        guard crashTime == nil else {
            // 允许重复调用，这样设计可以让多个崩溃采集工具都能够触发，但一次启动只能崩溃一次防止数据重复
            return
        }
        guard let folderDir = workspace else {
            return
        }
        crashTime = Date()
        let fileName = timeStr(format: "yyyy-MM-dd-HHmmssZ", date: crashTime!)
        let launchTimeStr = "\(timeStr(format: "yyyy-MM-dd HH:mm:ss Z", date: launchTime)) (\(launchTime.timeIntervalSince1970))"
        let crashTimeStr = "\(timeStr(format: "yyyy-MM-dd HH:mm:ss Z", date: crashTime!)) (\(crashTime!.timeIntervalSince1970))"
        // json
        let jsonFileURL = folderDir.appendingPathComponent(fileName + ".json")
        var json = [String: Any]()
        json["launchTime"] = launchTimeStr
        json["crashTime"] = crashTimeStr
        var jsonHeader = [String: Any]()
        var fileHeader = [String: Any]()
        var userInfo = [String: Any]()
        configCustomInfoCallback?(&jsonHeader, &fileHeader, &userInfo)
        jsonHeader.forEach { json[$0.key] = $0.value }
        if let name = name, name.count > 0 {
            json["crashName"] = name
        }
        if let reason = reason, reason.count > 0 {
            json["crashReason"] = reason
        }
        if JSONSerialization.isValidJSONObject(json) {
            if let data = try? JSONSerialization.data(withJSONObject: json) {
                FileManager.default.createFile(atPath: jsonFileURL.path, contents: data)
            }
        }
        
        // log
        let logFileURL = folderDir.appendingPathComponent(fileName + ".log")
        // content
        var text = "-------- base info --------\n"
        // header
        text.append("launch time: \(launchTimeStr)\n")
        text.append("crash time:  \(crashTimeStr)\n")
        fileHeader.forEach { kv in
            text.append("\(kv.key): \(kv.value)\n")
        }
        text.append("\n\n")
        // user info
        if userInfo.count > 0 {
            text.append("-------- status --------\n")
            userInfo.forEach { kv in
                text.append("\(kv.key): \(kv.value)\n")
            }
            text.append("\n\n")
        }
        // messages
        if allRecords.count > 0 {
            text.append("-------- events --------\n")
            allRecords.forEach { kv in
                text.append("\(kv.meta)\n")
                if !kv.message.isEmpty {
                    text.append("\(kv.message)\n")
                }
            }
            text.append("\n\n")
        }
        // crash info
        if configRecordExceptionDetail {
            text.append("-------- crash info --------\n")
            if let description = description, description.count > 0 {
                text.append(description)
            }
        }
        // save to file
        guard let data = text.data(using: .utf8) else {
            return
        }
        FileManager.default.createFile(atPath: logFileURL.path, contents: data)
    }
    
    /// 记录自定义崩溃信息（将会触发回调然后结束session）
    /// - Parameter exception: 崩溃信息
    public static func record(crash: NSException?) {
        recordException(name: crash?.name.rawValue, reason: crash?.reason, description: crash?.description)
    }
    
    /// 记录崩溃信息
    /// - Parameter crash: 崩溃信息
    static func record(crash: AppCrashTracer.CrashInfo) {
        recordException(name: crash.name, reason: crash.reason, description: crash.description)
    }
    
    static func timeStr(format: String, date: Date = Date()) -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    static func appendRecord(_ record: (meta: String, message: String)) {
        if allRecords.count >= maxRecordCount {
            allRecords.removeFirst()
        }
        allRecords.append(record)
    }
}

// MARK: - ObjC

public class AppCrashRecorderObjC: NSObject {
    @objc public static func customRecord(_ session: String, code: String, message: String?) {
        AppCrashRecorder.customRecord(session, code: code, message: message)
    }
    @objc public static func exportLogFiles() -> [URL] {
        AppCrashRecorder.exportLogFiles()
    }
    @objc public static func codeMeta(function: UnsafePointer<CChar>?, line: Int32) -> String {
        let fn: String?
        if let ff = function {
            fn = String.init(utf8String: ff)
        } else {
            fn = nil
        }
        return "\(fn ?? "unknown") <line:\(line)>"
    }
}
