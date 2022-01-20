//
//  SoundsDatasource.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 19.01.2022.
//

import Foundation

class SoundsDatasource {
    var fileNames: [String] = []

    func lookForFiles() {
        let path = Bundle.main.bundlePath
        if var files = try? FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath)
            .filter { $0.contains(".wav") || $0.contains(".mp3") } {
                fileNames = files.sorted()
                print(fileNames)
        }
    }
}
