//
//  AnimationFrameDecoder.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation
import UIKit.UIImage

struct AnimationFrameDecoder {
    private let prefix: String = "Step=#"
    private let stateNames: [Int: String] = [
        1: "Default",
        2: "Hover",
        3: "Activation",
        4: "Sound",
        5: "Blur",
        6: "Finishing"
    ]
    private let suffixNames: [Int: String] = [
        1: "",
        2: " 1-2",
        3: " 2-2"
    ]
    
    func getFramesStatesImageList(_ soundName: String) -> [UIImage] {
        var result: [String] = []
        for i in 1...6 {
            for j in 1...3 {
                if i == 1 && j == 1 || i == 2 && j == 1 || i == 3 && j == 1 {
                    continue
                }
                let index = i == 6 ? 5 : i
                let stateName = stateNames[i]!
                let suffix = suffixNames[j]!
                result.append("\(soundName)-\(prefix)\(index) \(stateName)\(suffix)")
            }
        }
        print(result)
        return result.map { UIImage(named: $0)! }
    }
}
