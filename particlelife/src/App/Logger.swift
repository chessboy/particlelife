//
//  Logger.swift
//  particlelife
//
//  Created by Rob Silverman on 2/22/25.
//

import Foundation

struct LoggerConfig {
    static let logLevelPadding = 8
    static let filenamePadding = 25
    static let logThreshold: LogLevel = .debug
    
    // Automatically detect if in debug mode
    #if DEBUG
    static var isLoggingEnabled: Bool = true
    #else
    static var isLoggingEnabled: Bool = false
    #endif
}

enum LogLevel: String {
    case error = "❌ ERROR"
    case warning = "⚠️ WARN"
    case info = "ℹ️ INFO"
    case debug = "🔍 DEBUG"
    
    var padded: String {
        return self.rawValue.padding(toLength: LoggerConfig.logLevelPadding, withPad: " ", startingAt: 0)
    }
    
    var rank: Int {
        switch self {
        case .error: return 3
        case .warning: return 2
        case .info: return 1
        case .debug: return 0
        }
    }
}

struct Logger {
    static func log(_ message: String, level: LogLevel = .info, function: String = #function, file: String = #file) {
        guard LoggerConfig.isLoggingEnabled, level.rank >= LoggerConfig.logThreshold.rank else { return }

        let filename = (file as NSString).lastPathComponent
        let paddedFilename = filename.padding(toLength: LoggerConfig.filenamePadding, withPad: " ", startingAt: 0)
        
        // Check if the message contains multiple lines
        let messageLines = message.split(separator: "\n", omittingEmptySubsequences: false)
        let firstLine = messageLines.first ?? ""
        let additionalLines = messageLines.dropFirst()
        
        // Print the first line normally
        print("\(level.padded) | \(paddedFilename) \(function) ➝ \(firstLine)")
        
        // Print additional lines with proper indentation
        for line in additionalLines {
            print("               | \(line)")
        }
    }
}

extension Logger {
    static func logWithError(_ message: String, error: Error, function: String = #function, file: String = #file) {
        let filename = (file as NSString).lastPathComponent
        let paddedFilename = filename.padding(toLength: LoggerConfig.filenamePadding, withPad: " ", startingAt: 0)
        let paddedLevel = LogLevel.error.padded  // Use the same padding logic as other logs
        
        print("\(paddedLevel) | \(paddedFilename) \(function) ➝ \(message): \(error.localizedDescription)")
    }
}
