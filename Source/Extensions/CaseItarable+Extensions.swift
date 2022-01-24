//
//  CaseItarable+Extensions.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 23.01.2022.
//

import Foundation

extension CaseIterable where Self: RawRepresentable {
    static var allValues: [RawValue] {
        return allCases.map { $0.rawValue }
    }
}
