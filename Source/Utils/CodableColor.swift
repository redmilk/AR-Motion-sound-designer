//
//  CodableColor.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 22.01.2022.
//

import UIKit.UIColor

struct Color: Codable {
    var red: CGFloat = 0.0, green: CGFloat = 0.0, blue: CGFloat = 0.0, alpha: CGFloat = 0.0
    var uiColor: UIColor { UIColor(red: red, green: green, blue: blue, alpha: alpha) }
    
    init(uiColor: UIColor) {
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    }
}

@propertyWrapper struct CodableColor {
    var wrappedValue: UIColor
}

extension CodableColor: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        guard let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid color")
        }
        wrappedValue = color
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = try NSKeyedArchiver.archivedData(withRootObject: wrappedValue, requiringSecureCoding: true)
        try container.encode(data)
    }
}
