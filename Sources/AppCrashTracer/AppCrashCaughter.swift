//
//  AppCrashCaughter.swift
//  CrashTracerDemo
//
//  Created by xaoxuu on 2022/4/22.
//

import UIKit

fileprivate var exceptionCount: Int32 = 0

extension AppCrashTracer {
    struct CrashInfo {
        var name = ""
        var reason: String?
        var userInfo: [AnyHashable: Any]?
        var callStackSymbols = [String]()
        var description: String {
            var text = ""
            text.append("name: \(name)\n")
            if let reason = reason {
                text.append("reason: \(reason)\n")
            }
            if let userInfo = userInfo as? [String: Any] {
                text.append("user info: \(userInfo)\n")
            }
            text.append("call stack symbols:\n\(callStackSymbols.joined(separator: "\n"))\n")
            return text
        }
    }
}

fileprivate var callback: ((_ exp: AppCrashTracer.CrashInfo) -> Void)?

private func UncaughtExceptionHandler(_ exception: NSException) {
    callback?(AppCrashTracer.CrashInfo(name: exception.name.rawValue, reason: exception.reason, userInfo: exception.userInfo, callStackSymbols: exception.callStackSymbols))
    exception.raise()
}

private func UncaughtSignalHandler(_ sig: Int32) {
    guard OSAtomicDecrement32(&exceptionCount) < 20 else {
        return
    }
    let name: String
    let reason: String
    switch sig {
    case 4:
        name = "SIGILL"
        reason = "illegal instruction (not reset when caught)"
    case 5:
        name = "SIGTRAP"
        reason = "trace trap (not reset when caught)"
    case 6:
        name = "SIGABRT"
        reason = "abort()"
    case 8:
        name = "SIGFPE"
        reason = "floating point exception"
    case 10:
        name = "SIGBUS"
        reason = "bus error"
    case 11:
        name = "SIGSEGV"
        reason = "segmentation violation"
    case 13:
        name = "SIGPIPE"
        reason = "write on a pipe with no one to read it"
    default:
        name = "SIGNAL \(sig)"
        reason = "Signal \(sig) was raised."
    }
    callback?(AppCrashTracer.CrashInfo(name: name, reason: reason, userInfo: ["signal": sig], callStackSymbols: Thread.callStackSymbols))
    signal(sig, SIG_DFL)
    raise(sig)
}

extension AppCrashTracer {
    struct Caughter {}
}

extension AppCrashTracer.Caughter {
    
    static func start() {
        NSSetUncaughtExceptionHandler(UncaughtExceptionHandler(_:))
        signal(SIGABRT, UncaughtSignalHandler)
        signal(SIGILL, UncaughtSignalHandler)
        signal(SIGSEGV, UncaughtSignalHandler)
        signal(SIGFPE, UncaughtSignalHandler)
        signal(SIGBUS, UncaughtSignalHandler)
        signal(SIGPIPE, UncaughtSignalHandler)
        signal(SIGTRAP, UncaughtSignalHandler)
    }
    
    static func stop() {
        NSSetUncaughtExceptionHandler(nil)
        signal(SIGABRT, SIG_DFL)
        signal(SIGBUS, SIG_DFL)
        signal(SIGFPE, SIG_DFL)
        signal(SIGILL, SIG_DFL)
        signal(SIGPIPE, SIG_DFL)
        signal(SIGSEGV, SIG_DFL)
        signal(SIGTRAP, SIG_DFL)
    }
    
    static func onException(_ handler: @escaping (AppCrashTracer.CrashInfo) -> Void) {
        start()
        callback = handler
    }
    
}
