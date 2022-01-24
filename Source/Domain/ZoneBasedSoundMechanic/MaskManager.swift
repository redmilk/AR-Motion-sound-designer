//
//  MaskManager.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Combine
import UIKit.UIPasteboard

struct MaskDescription {
    var orderNumber: Int
    var masksTotal: Int
    var currentMasksZonesTotal: Int
    var currentMasksUniqueSoundsTotal: Int
    var createdWith: String
    var shouldForcePlayAll: Bool
}

enum MaskPreset: Encodable, Hashable {
    case editor(String), mask64(String), other(String)
}

final class MaskManager: MaskEditorProvider {
    enum Input {
        case getNextMask
        case getPrevious
    }
    enum Response {
        case importedMask(MaskBase)
        case nextMask(MaskBase, MaskDescription)
    }
    var input = PassthroughSubject<Input, Never>()
    var output = PassthroughSubject<Response, Never>()
    var activeMask: MaskPreset? = .editor("Lightsaber")
    var shouldForceplaySoundForCurrentMask: Bool { return false }
    
    var activeMaskData: MaskProtocol? {
        guard let activeMask = activeMask else { return nil }
        return maskPresets[activeMask]
    }
    @UD(.savedMaskList, [])
    private var savedMaskList: [String]!
    @UD(.savedMaskListTotal, 0)
    private var savedMaskListTotal: Int!
    private var bag = Set<AnyCancellable>()

    private var maskPresets: [MaskPreset: MaskBase] = [:]
    private var maskListForEditor: [MaskBase] = [] {
        didSet {
            if maskListForEditor.isEmpty && !maskPresets.isEmpty {
                maskListForEditor = Array(maskPresets.values)
            }
        }
    }
    
    init() {
        let allPossibleMask = MaskAutoMapper(template: .unknown, soundsPrefixList: ["meditation-", "Lightsaber"]).generateAllTemplates()
        let presets = allPossibleMask.map { MaskPreset.editor($0.zonePresets.values.first?.soundName ?? "Suck my ass") }
        var results = [MaskPreset: MaskBase]()
        for i in 0..<allPossibleMask.count {
            let preset = presets[i]
            let mask = allPossibleMask[i]
            results.updateValue(mask, forKey: preset)
        }
        let mask = results.values.first
        maskPresets = results
        maskPresets[MaskPreset.editor("dfhasdkfhf")] = mask
        activeMask = .editor("dfhasdkfhf")
        editor.mask = mask!
        maskListForEditor = Array(maskPresets.values)
        output.send(.importedMask(mask!))
        input.sink(receiveValue: { [weak self] input in
            switch input {
            case .getNextMask:
                self?.respondWithNextMask()
            case .getPrevious:
                self?.respondWithNextMask()
            }
        }).store(in: &bag)
    }
    
    private func respondWithNextMask() {
        print(maskListForEditor.count)
        print(maskPresets.count)
        guard !maskListForEditor.isEmpty else { return }
        let mask = maskListForEditor.removeFirst()
        var description = MaskDescription(orderNumber: maskListForEditor.count, masksTotal: maskPresets.count, currentMasksZonesTotal: mask.totalNumberOfZones, currentMasksUniqueSoundsTotal: mask.totalNumberOfUniqueSounds, createdWith: mask.createdWith ?? "", shouldForcePlayAll: mask.shouldForcaplaySounds)
        output.send(.nextMask(mask, description))
    }

 
    func saveMask(with json: String) {
        if var saved = savedMaskList, var savedTotal = savedMaskListTotal {
            saved.append(contentsOf: saved)
            Logger.log("Saved mask count: \(saved.count)", type: .editor)
            savedMaskList = saved
            savedTotal = savedTotal + 1
        }
    }
    
    func exportJSON(with mask: MaskBase, isPrettyPrinted: Bool = false) -> String? {
        let encoder = JSONEncoder()
        isPrettyPrinted ? encoder.outputFormatting = .prettyPrinted : ()
        guard let data = try? encoder.encode(mask) else { return nil }
        let jsonString = String(data: data, encoding: .utf8)
        print(jsonString)
        return jsonString
    }
    
    func importFromClipboard() {
        guard !(UIPasteboard.general.string ?? "").isEmpty,
              let content = UIPasteboard.general.string,
              let mask = importMask(as: content) else { return }
        maskPresets[MaskPreset.editor("dfhasdkfhf")] = mask
        activeMask = .editor("dfhasdkfhf")
        editor.mask = mask
        output.send(.importedMask(mask))
    }
    
    private func importMask(as jsonString: String) -> MaskBase? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            let mask = try JSONDecoder().decode(MaskBase.self, from: data)
            Logger.log("Import mask", type: .editor)
            return mask
        } catch {
            Logger.logError(error)
        }
        return nil
    }
}
