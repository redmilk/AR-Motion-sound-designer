//
//  UserDefaultsPropertyWrapper.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 19.11.2021.
//

import Foundation

enum UDK: String, CaseIterable {
    case savedMaskList, savedMaskListTotal
}

@propertyWrapper struct UD<Value: Codable> {
    private let key: UDK
    private let defaultValue: Value
    private let ud: UserDefaults = .standard
    
    init(_ key: UDK, _ defaultValue: Value) {
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: Value {
        get {
            if let data = ud.value(forKey: key.rawValue) as? Data,
               let dict = try? PropertyListDecoder().decode([Value].self, from: data) {
                return dict.first!
            }
            return defaultValue
        }
        set {
            let value = try? PropertyListEncoder().encode([newValue])
            ud.setValue(value, forKey: key.rawValue)
        }
    }
}
