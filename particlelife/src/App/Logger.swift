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

class Logger {
    static let shared = Logger()
    
    private let logFileURL: URL?
    
    private init() {
        if FeatureFlags.enableLogging.isOn {
            let fileManager = FileManager.default
            if let logsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                logFileURL = logsDirectory.appendingPathComponent("particlelife.log")
                
                // Clear old logs on startup
                if let logFileURL = logFileURL {
                    try? fileManager.removeItem(at: logFileURL)
                    writeToFile("=== Particle Life Log Started ===\n")
                }
            } else {
                logFileURL = nil
            }
        } else {
            logFileURL = nil
        }
    }

    static func log(_ message: String,
                    level: LogLevel = .info,
                    function: String = #function,
                    file: String = #file,
                    showCaller: Bool = false) {
        
        guard FeatureFlags.enableLogging.isOn, level.rank >= LoggerConfig.logThreshold.rank else { return }
        
        let filename = (file as NSString).lastPathComponent
        let paddedFilename = filename.padding(toLength: LoggerConfig.filenamePadding, withPad: " ", startingAt: 0)
        
        var logMessage = "\(level.padded) | \(paddedFilename) \(function) ➝ \(message)"
        
        if showCaller {
            if let callerInfo = Thread.callStackSymbols.dropFirst(2).first {
                let extractedFunction = extractFunctionName(from: callerInfo)
                let cleanedFunction = cleanMangledSymbol(extractedFunction)
                logMessage += " (called by: \(cleanedFunction))"
            }
        }
        
        shared.writeToFile(logMessage + "\n")
        print(logMessage)
    }
    
    static func logWithError(_ message: String, error: Error, function: String = #function, file: String = #file) {
        log("\(message): error: \(error.localizedDescription)", level: .error, function: function, file: file)
    }
    
    private func writeToFile(_ text: String) {
        guard FeatureFlags.enableFileLogging.isOn, let logFileURL = logFileURL else { return }
        if let handle = try? FileHandle(forWritingTo: logFileURL) {
            handle.seekToEndOfFile()
            if let data = text.data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        } else {
            try? text.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }
    
    /// Returns the log file path for external retrieval
    static func logFilePath() -> String? {
        return shared.logFileURL?.path
    }
    
    /// Extracts function name from stack trace
    private static func extractFunctionName(from symbol: String) -> String {
        let regex = try? NSRegularExpression(pattern: "\\s+(\\S+)\\s+\\+")
        let match = regex?.firstMatch(in: symbol, range: NSRange(location: 0, length: symbol.count))
        return match.map { (symbol as NSString).substring(with: $0.range(at: 1)) } ?? "Unknown Function"
    }
    
    /// Cleans up Swift-mangled symbols for readability
    private static func cleanMangledSymbol(_ mangled: String) -> String {
        // Remove Swift mangling prefix (e.g., `$s13Particle_Life`)
        var cleaned = mangled.replacingOccurrences(of: "^\\$s\\d+[A-Za-z_]+", with: "", options: .regularExpression)
        
        // Remove trailing Swift type markers (`C` for class, `V` for struct, etc.)
        cleaned = cleaned.replacingOccurrences(of: "[CV]$", with: "", options: .regularExpression)
        
        // Attempt to split at numbers (Swift often uses numbers between class and function names)
        let components = cleaned.split(whereSeparator: { $0.isNumber })
        
        // If we have at least 2 components, return "Class.Function" or "Class.Property"
        if components.count >= 2 {
            return "\(components[0]).\(components[1])"
        }
        
        // Otherwise, return just the class name
        return components.first.map(String.init) ?? cleaned
    }
}
