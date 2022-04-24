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
        
        public static var maxRecordCount = 50
        
        /// 所有的手动record文本
        static var records = [(meta: String, message: String)]()
        
        static var workspace: URL?
        
        static let dateFormatter = DateFormatter()
        
        fileprivate static var launchTime = Date()
        
        fileprivate static var jsonHeaderCallback: ((_ jsonHeader: inout [String: Any]) -> Void)?
        fileprivate static var fileHeaderCallback: ((_ fileHeader: inout [String: Any]) -> Void)?
        fileprivate static var userInfoCallback: ((_ userInfo: inout [String: Any]) -> Void)?
        
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
    /// - Parameters:
    ///   - jsonHeader: json格式的崩溃日志的header
    ///   - fileHeader: log格式的崩溃日志的header
    public static func configJsonFileHeader(callback: @escaping (_ header: inout [String: Any]) -> Void) {
        jsonHeaderCallback = callback
    }
    public static func configLogFileHeader(callback: @escaping (_ header: inout [String: Any]) -> Void) {
        fileHeaderCallback = callback
    }
    public static func configUserInfo(callback: @escaping (_ userInfo: inout [String: Any]) -> Void) {
        userInfoCallback = callback
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
    
    /// 记录崩溃信息
    /// - Parameter exception: 崩溃信息
    static func record(exception: AppCrashTracer.CrashInfo) {
        guard let folderDir = workspace else {
            return
        }
        let crashTime = Date()
        let fileName = timeStr(format: "yyyy-MM-dd-HHmmssZ", date: crashTime)
        let launchTimeStr = "\(timeStr(format: "yyyy-MM-dd HH:mm:ss Z", date: launchTime)) (\(launchTime.timeIntervalSince1970))"
        let crashTimeStr = "\(timeStr(format: "yyyy-MM-dd HH:mm:ss Z", date: crashTime)) (\(crashTime.timeIntervalSince1970))"
        // json
        let jsonFileURL = folderDir.appendingPathComponent(fileName + ".json")
        var json = [String: Any]()
        json["launchTime"] = launchTimeStr
        json["crashTime"] = crashTimeStr
        var jsonHeader = [String: Any]()
        jsonHeaderCallback?(&jsonHeader)
        jsonHeader.forEach { json[$0.key] = $0.value }
        json["crashName"] = exception.name
        if let reason = exception.reason {
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
        var fileHeader = [String: Any]()
        fileHeaderCallback?(&fileHeader)
        fileHeader.forEach { kv in
            text.append("\(kv.key): \(kv.value)\n")
        }
        text.append("\n\n")
        // user info
        userInfoCallback?(&AppCrashTracer.userInfo)
        if AppCrashTracer.userInfo.count > 0 {
            text.append("-------- status --------\n")
            AppCrashTracer.userInfo.forEach { kv in
                text.append("\(kv.key): \(kv.value)\n")
            }
            text.append("\n\n")
        }
        // messages
        if records.count > 0 {
            text.append("-------- events --------\n")
            records.forEach { kv in
                text.append("\(kv.meta)\n")
                if !kv.message.isEmpty {
                    text.append("\(kv.message)\n")
                }
            }
            text.append("\n\n")
        }
        // crash info
        text.append("-------- crash info --------\n")
        text.append(exception.description)
        guard let data = text.data(using: .utf8) else {
            return
        }
        FileManager.default.createFile(atPath: logFileURL.path, contents: data)
    }
    static func timeStr(format: String, date: Date = Date()) -> String {
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: date)
    }
    static func appendRecord(_ record: (meta: String, message: String)) {
        if records.count >= maxRecordCount {
            records.removeFirst()
        }
        records.append(record)
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
