//
//  PerformanceMeasurement.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 15.12.2021.
//

import UIKit
import Combine
import QuartzCore

public class PerfmormanceMeasurment: NSObject {
    enum Action {
        case startMeasure
        case stopMeasure
    }
    
    enum Response {
        case measurement(fps: String)
        case inferenceMeasurment(inferenceTime: String)
    }
    
    class DisplayLinkProxy: NSObject {
        @objc weak var parentCounter: PerfmormanceMeasurment?
        @objc func updateFromDisplayLink(_ displayLink: CADisplayLink) {
            parentCounter?.updateFromDisplayLink(displayLink)
        }
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    private var bag = Set<AnyCancellable>()
    
    @objc public var notificationDelay: TimeInterval = 2.0
    private let displayLink: CADisplayLink
    private let displayLinkProxy: DisplayLinkProxy
    private var runloop: RunLoop?
    private var mode: RunLoop.Mode?
    private var lastNotificationTime: CFAbsoluteTime = 0.0
    private var numberOfFrames = 0
    
    
    var inferenceMeasurement = [
        "start": CACurrentMediaTime(),
        "end": CACurrentMediaTime()
    ]
    var isMeasuring: Bool = false
    
    func startMeasure() {
        if isMeasuring { return }
        isMeasuring = true
        inferenceMeasurement["start"] = CACurrentMediaTime()
    }
    func stopMeasure() {
        isMeasuring = false
        inferenceMeasurement["stop"] = CACurrentMediaTime()
        if let startTime = inferenceMeasurement["start"],
           let endTime = inferenceMeasurement["end"] {
            let inferenceTime = endTime - startTime
            let inferenceTimeString = "inference: \(Int(inferenceTime * 1000.0)) ms"
            
        }

    }
    
    public override init() {
        displayLinkProxy = DisplayLinkProxy()
        displayLink = CADisplayLink(
            target: displayLinkProxy,
            selector: #selector(DisplayLinkProxy.updateFromDisplayLink(_:))
        )
        super.init()
        displayLinkProxy.parentCounter = self
        
        input
            .sink(receiveValue: { [weak self] action in
                switch action {
                case .startMeasure:
                    self?.startTracking()
                case .stopMeasure:
                    self?.stopTracking()
                }
            })
            .store(in: &bag)
    }
    deinit { displayLink.invalidate() }

    @objc private func startTracking(inRunLoop runloop: RunLoop = .main, mode: RunLoop.Mode = .common) {
        stopTracking()
        self.runloop = runloop
        self.mode = mode
        self.displayLink.add(to: runloop, forMode: mode)
    }

    @objc private func stopTracking() {
        guard let runloop = self.runloop, let mode = self.mode else { return }
        displayLink.remove(from: runloop, forMode: mode)
        self.runloop = nil
        self.mode = nil
    }

    private func updateFromDisplayLink(_ displayLink: CADisplayLink) {
        if lastNotificationTime == 0.0 {
           lastNotificationTime = CFAbsoluteTimeGetCurrent()
            return
        }
        numberOfFrames += 1
        let currentTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = currentTime - self.lastNotificationTime
        if elapsedTime >= notificationDelay {
            notifyUpdateForElapsedTime(elapsedTime)
            lastNotificationTime = 0.0
            numberOfFrames = 0
        }
    }

    private func notifyUpdateForElapsedTime(_ elapsedTime: CFAbsoluteTime) {
        let fps = Int(round(Double(numberOfFrames) / elapsedTime))
        output.send(.measurement(fps: "fps: \(fps)"))
    }
}
/// Old impl.
/*
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
 */
