//
//  Dictionary+Extensions.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 22.01.2022.
//

import Foundation

extension Dictionary {
    var jsonData: Data? { try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) }
    
    var stringJSON: String? { String(data: jsonData ?? Data(), encoding: .utf8) }
    
    func decode<T: Codable>() throws -> T? { try JSONDecoder().decode(T.self, from: jsonData ?? Data()) }
}
