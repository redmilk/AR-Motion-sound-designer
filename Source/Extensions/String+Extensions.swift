//
//  String+Extensions.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 22.01.2022.
//

import Foundation

extension String {
    static var emojiString: String {
        String(UnicodeScalar(Array(0x1F300...0x1F3F0).randomElement()!)!)
    }
}


