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
        
        public static var header = [String: Any]()
        
        static var records = [(meta: String, message: String)]()
        
        static var folderName: String = "Crashes"

        static var workspace: URL? {
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(folderName, isDirectory: true)
        }
        
        static let dateFormatter = DateFormatter()
        
        fileprivate static let launchTime = Date()
        
    }
}

public typealias AppCrashRecorder = AppCrashTracer.Recorder

public extension AppCrashTracer.Recorder {
    
    /// 记录
    /// - Parameters:
    ///   - session: trace session
    static func record(_ session: Session, file: String = #file, function: String = #function, line: Int = #line) {
        let meta = "[\(timeStr(format: "MM-dd HH:mm:ss"))][\(session.identifier)] " + (file as NSString).lastPathComponent + " \(function) <line:\(line)>"
        records.append((meta: meta, message: ""))
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
        records.append((meta: meta, message: message))
    }
    
    /// 记录
    /// - Parameters:
    ///   - session: trace session
    ///   - code: code信息
    ///   - messages: 额外需要记录的内容
    static func customRecord(_ session: String, code: String, message: String? = nil) {
        records.append((meta: "[\(timeStr(format: "MM-dd HH:mm:ss"))][\(session)] " + code, message: message ?? ""))
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
        return urls.filter { $0.pathExtension == "log" }
    }
    
    static func exportLogObjects() -> [[String: Any]] {
        guard let workspace = workspace else {
            return []
        }
        var urls = [URL]()
        if let dirEnum = FileManager.default.enumerator(atPath: workspace.path) {
            var logs = (dirEnum.allObjects as? [String]) ?? [String]()
            logs.sort()
            urls = logs.map { workspace.appendingPathComponent($0) }
        }
        urls = urls.filter { $0.pathExtension == "json" }
        var objs = [[String: Any]]()
        urls.forEach { fileURL in
            do {
                let data = try Data.init(contentsOf: fileURL)
                let obj = try JSONSerialization.jsonObject(with: data)
                if let dict = obj as? [String: Any] {
                    objs.append(dict)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        return objs
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
    static func onCrash(exception: AppCrashTracer.CrashInfo) {
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
        header.forEach { json[$0.key] = $0.value }
        json["crashInfo"] = exception.dict
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
        header.forEach { kv in
            text.append("\(kv.key): \(kv.value)")
        }
        text.append("\n\n")
        // messages
        if records.count > 0 {
            text.append("-------- trace info --------\n")
            records.forEach { kv in
                text.append("\(kv.meta)\n")
                if !kv.1.isEmpty {
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
}


