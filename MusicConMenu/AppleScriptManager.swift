//
//  AppleScriptManager.swift
//  MusicConMenu
//
//  Created by Yuichi Yoshida on 2024/11/05.
//

import Cocoa
import Foundation

protocol CreatableFromNSAppleEventDescriptor {
    static func get(a:NSAppleEventDescriptor) throws -> Self
}

extension Int : CreatableFromNSAppleEventDescriptor {
    static func get(a:NSAppleEventDescriptor) throws -> Self {
        return Int(a.int32Value)
    }
}

extension String : CreatableFromNSAppleEventDescriptor {
    static func get(a:NSAppleEventDescriptor) throws -> Self {
        guard let string = a.stringValue else {
            throw AppleScriptManagerError.canNotGetString
        }
        return string
    }
}

enum AppleScriptManagerError: Error {
    case appleScriptError
    case appleScriptExecutionError(Dictionary<String, Any>)
    case canNotGetString
}

class AppleScriptManager {
    
    static func call(script: String) throws -> NSAppleEventDescriptor {
        var error: NSDictionary?
        guard let scriptObject = NSAppleScript(source: script) else {
            throw AppleScriptManagerError.appleScriptError
        }
        let output = scriptObject.executeAndReturnError(&error)
        if let error {
            var dicitonary: [String: Any] = [:]
            for key in error.allKeys {
                if let key = key as? String {
                    dicitonary[key] = error[key]
                }
            }
            throw AppleScriptManagerError.appleScriptExecutionError(dicitonary)
        }
        return output
    }
    
    static func execute<A: CreatableFromNSAppleEventDescriptor>(script: String) throws -> A {
        let output = try call(script: script)
        return try A.get(a: output)
    }
    
    static func execute<A: CreatableFromNSAppleEventDescriptor>(script: String) throws -> [A] {
        let output = try call(script: script)
        var array: [A] = []
        for i in 0..<output.numberOfItems {
            if let obj = output.atIndex(i) {
                array.append(try A.get(a: obj))
            }
        }
        return array
    }
}
