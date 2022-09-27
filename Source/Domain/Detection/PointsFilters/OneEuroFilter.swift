//
//  OneEuroFilter.swift
//  Jiggle
//
//  Created by Danyl Timofeyev on 09.12.2021.
//

import Foundation

final class OneEuroFilter {
    var prevT: Float
    var prevX: Float
    var prevDx: Float
    var minCutoff: Float
    var beta: Float
    var dCutoff: Float
    var prevUnfilteredX: Float?
    
    init(t0: Float, x0: Float, dx0: Float = 0.0, minCutoff: Float = 1.0, beta: Float = 0.09, dCutoff: Float = 1.0) {
        self.prevT = t0
        self.prevX = x0
        self.prevDx = dx0
        self.minCutoff = minCutoff
        self.beta = beta
        self.dCutoff = dCutoff
    }
    
    func smoothingFactor(cutoff: Float, dT: Float) -> Float {
        let r = 2 * Float.pi * cutoff * dT
        return r/(1+r)
    }
    
    func exponentialSmoothing(alpha: Float, x: Float, prevFilteredX: Float) -> Float {
        let filteredSignal = alpha * x + (1 - alpha) * prevFilteredX
        return filteredSignal
    }
    
    func filter(t: Float, x: Float) -> Float {
        
        // avoid stream of duplicated x
        if let prevUnfilteredX = prevUnfilteredX {
            if x == prevUnfilteredX {
                return prevX
            }
        }
        
        // avoid dt = 0 -> avoid division by 0
        let dt = (t == prevT) ? 1.0/30.0 : t - prevT
        
        // The filtered derivative of the signal.
        let dAlpha = smoothingFactor(cutoff: dCutoff, dT: dt)
        let dx = (x - prevX)/dt
        let dxFiltered = exponentialSmoothing(alpha: dAlpha, x: dx, prevFilteredX: prevDx)
        
        // The filtered signal
        let cutoff = minCutoff + beta * abs(dxFiltered)
        let alpha = smoothingFactor(cutoff: cutoff, dT: dt)
        let xFiltered = exponentialSmoothing(alpha: alpha, x: x, prevFilteredX: prevX)
        
        self.prevT = t
        self.prevX = xFiltered
        self.prevDx = dxFiltered
        self.prevUnfilteredX = x
        
        return xFiltered
    }
}
