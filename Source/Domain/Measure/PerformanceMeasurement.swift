//
//  PerformanceMeasurement.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 15.12.2021.
//

import UIKit
import Combine

final class PerfmormanceMeasurment {
    
    enum Response {
        case measurement(inference: String, execution: String, fps: String)
    }
    
    let output = PassthroughSubject<Response, Never>()
    private var bag = Set<AnyCancellable>()
    
    var index: Int = -1
    var measurements: [Dictionary<String, Double>] = [[:]]
    
    init() {
        let measurement = [
            "start": CACurrentMediaTime(),
            "end": CACurrentMediaTime()
        ]
        measurements = Array<Dictionary<String, Double>>(repeating: measurement, count: 30)
    }
    
    // start
    func startMeasure() {
        index += 1
        index %= 30
        guard index < measurements.count else { return }
        measurements[index] = [:]
        
        labelWith(for: index, with: "start")
    }
    
    // stop
    func stopMeasure() {
        labelWith(for: index, with: "end")
        
        let beforeMeasurement = getBeforeMeasurment(for: index)
        let currentMeasurement = measurements[index]
        if let startTime = currentMeasurement["start"],
            let endInferenceTime = currentMeasurement["endInference"],
            let endTime = currentMeasurement["end"],
            let beforeStartTime = beforeMeasurement["start"] {
            
            let inferenceTime = endInferenceTime - startTime
            let inferenceTimeString = "inference: \(Int(inferenceTime * 1000.0)) ms"
            
            let executionTime = endTime - startTime
            let executionTimeString = "execution: \(Int(executionTime * 1000.0)) ms"
            
            let fps = Int(1/(startTime - beforeStartTime))
            let fpsString = "fps: \(fps)"
            
            output.send(.measurement(
                inference: inferenceTimeString,
                execution: executionTimeString,
                fps: fpsString))
        }
        
    }
    
    // labeling with
    func labelMeasurment(with msg: String? = "") {
        labelWith(for: index, with: msg)
    }
    
    private func labelWith(for index: Int, with msg: String? = "") {
        if let message = msg {
            guard index < measurements.count else { return }
            measurements[index][message] = CACurrentMediaTime()
        }
    }
    
    private func getBeforeMeasurment(for index: Int) -> Dictionary<String, Double> {
        return measurements[(index + 30 - 1) % 30]
    }
}
