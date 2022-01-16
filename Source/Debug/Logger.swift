//
//  Logger.swift
//  ReactiveMovies
//
//  Created by Danyl Timofeyev on 01.05.2021.
//

import Foundation

enum LoggerTypes: Int {
    case all
    case requests
    case responses
    case lifecycle
    case sockets
    case notifications
    case redirectURL
    case token
    case subscriptionFinished
    case deinited
    case errorDescription
    case grid
}

final class Logger {
    
    private static var time: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        return dateFormatter.string(from: Date())
    }

    /// set false for disabling concole logs
    private static var isEnabled: Bool = true
    
    static func logError(_ error: Error?,
                    descriptions: String? = "",
                    path: String = #file,
                    line: Int = #line,
                    function: String = #function
    ) {
        Swift.print("--- \(time) ❌ ❌ ❌ ERROR \nFunction: \((function as NSString).lastPathComponent), File: \((path as NSString).lastPathComponent), Line: \((line.description as NSString).lastPathComponent)")

        if let e = error {
            debugPrint(e)
        }

        if !(descriptions ?? "").isEmpty {
            Swift.print(descriptions!)
            Swift.print(" ")
        }
    }

    static func log(_ string: String? = "",
                    type: LoggerTypes = .all,
                    function: String = #function,
                    path: String = #file,
                    line: Int = #line
    ) {
        if let s = string, !s.isEmpty {
            Logger.prepare("\(s)", type: type, function: function, path: path, line: line)
        } else {
            prepare("\(function)", type: type)
        }
    }

    /// Pretty printed json from Data
    static func log(_ data: Data?) {
        guard let data = data else { return }
        if let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers),
           let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            Logger.prepare(String(decoding: jsonData, as: UTF8.self), type: .responses)
        }
    }

    static func log(_ url: URL?) {
        guard let url = url else {
            return
        }

        Logger.prepare(url.absoluteString, type: .redirectURL)
    }

    static func logCurrentThread() {
        Swift.print("\r⚡️: \(Thread.current)\r" + "🏭: \(OperationQueue.current?.underlyingQueue?.label ?? "None")\r")
    }

    private static func prepare(_ string: String,
                                type: LoggerTypes,
                                function: String = #function,
                                path: String = #file,
                                line: Int = #line
    ) {
        switch type {
        /// just comment unnecessary printing logs
        case .all:
            print(str: "--- \(time) 🟨 " + string + "\nFunction: \((function as NSString).lastPathComponent), File: \((path as NSString).lastPathComponent), Line: \((line.description as NSString).lastPathComponent)")
        case .responses:
            print(str:"--- \(time) ✅ Response " + string)
        case .requests:
            print(str:"--- \(time) 📡 Request " + string)
        case .lifecycle:
            print(str:"--- \(time) 🔄 Lifecycle " + string)
        case .sockets:
            print(str:"--- \(time) 🧦 Sockets " + string)
        case .notifications:
            print(str:"--- \(time) 📩 Notifications " + string)
        case .redirectURL:
            print(str:"--- \(time) 🔀 Redirect URL " + string)
        case .token:
            print(str:"--- \(time) 🧬 Token " + string)
        case .subscriptionFinished:
            print(str:"--- \(time) 🗑 Finished " + string)
        case .deinited:
            print(str:"--- \(time) 🚯 Deinit " + string)
        case .errorDescription:
            print(str:"--- \(time) ❌❌❌ Error " + string)
        case .grid:
            print(str:"--- \(time) 🕸🕸🕸 Grid " + string)
        }
    }
    
    private static func print(str: String) {
        guard isEnabled else { return }
        
        #if DEBUG
        Swift.print(str)
        #endif
    }
}
