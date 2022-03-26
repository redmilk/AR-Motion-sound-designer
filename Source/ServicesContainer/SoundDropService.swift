//
//  SoundDrop.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 25.03.2022.
//

import Foundation

final class SoundDropService {
    func receiveSoundFile(_ url: URL) {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = url.lastPathComponent
        let destURL = documentsUrl.appendingPathComponent(fileName)
        if fileName.hasSuffix(".wav") || fileName.hasSuffix(".mp3") {
            do {
                if FileManager.default.fileExists(atPath: destURL.path) {
                    try FileManager.default.removeItem(at: destURL)
                }
                try FileManager.default.copyItem(at: url, to: destURL)
            } catch {
                Logger.logError(error)
            }
        }
    }
}
