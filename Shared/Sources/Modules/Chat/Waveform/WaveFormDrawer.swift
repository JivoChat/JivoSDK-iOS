//
//  WaveFormDrawer.swift
//  App
//
//  Created by Yulia Popova on 07.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import UIKit
import Accelerate

final class WaveFormDrawer {
    
    static var shared = WaveFormDrawer()
    
    func image(
        samples: [Float],
        configuration: WaveformConfiguration
    ) -> UIImage? {
        return UIGraphicsImageRenderer(size: configuration.size).image { context in
            context.cgContext.setAllowsAntialiasing(true)
            context.cgContext.setShouldAntialias(true)
            drawBackground(context.cgContext, configuration)
            context.cgContext.saveGState()
            
            context.cgContext.setLineWidth(configuration.lineWidth)
            context.cgContext.setLineCap(.round)
            
            let amountOfLines = Int((configuration.size.width + configuration.space) / (configuration.lineWidth + configuration.space))
            
            var resultedSamples = samples
            
            while resultedSamples.count < amountOfLines { resultedSamples.append(0) }
            
            let sampleParts = normalize(resultedSamples.chunked(into: resultedSamples.count / amountOfLines))
            let localMaxes = sampleParts.compactMap({ Float($0.reduce(0, +)) / Float($0.count) })
            
            drawGraph(localMaxes, context.cgContext, configuration)
            
            context.cgContext.restoreGState()
        }
    }
    
    private func drawBackground(
        _ context: CGContext,
        _ configuration: WaveformConfiguration) {
            context.setFillColor(configuration.backgroundColor.cgColor
            )
            context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
        }
    
    private func drawGraph(_ samples: [Float],
                           _ context: CGContext,
                           _ config: WaveformConfiguration) {
        let globalMax = samples.max() ?? 0
        
        let defaultAmplitude = (config.pickToPickAmplitude - config.lineWidth) / 2
        let yCenter = config.size.height / 2
        
        
        let path = CGMutablePath()
        
        for i in 0..<samples.count {
            let ampliduteCoef = CGFloat(min(globalMax, samples[i] / globalMax))
            let drawingAmplitudeUp = yCenter - defaultAmplitude * ampliduteCoef
            let drawingAmplitudeDown = yCenter + defaultAmplitude * ampliduteCoef
            
            let x = CGFloat(i) * (config.space + config.lineWidth) + config.lineWidth * 0.5
            
            path.move(to: CGPoint(x: x, y: drawingAmplitudeUp))
            path.addLine(to: CGPoint(x: x, y: drawingAmplitudeDown))
        }
        
        context.addPath(path)
        context.setStrokeColor(config.color.cgColor)
        context.strokePath()
    }
    
    private func normalize(_ samples: [[Float]]) -> [[Float]] {
        if samples.count < 3 { return samples }
        
        var normalizedSamples: [[Float]] = []
        
        for i in 0..<samples.count {
            if i == 0 {
                normalizedSamples.append(samples[0] + samples[1])
            } else if i == samples.count - 1 {
                normalizedSamples.append(samples[i] + samples[i - 1])
            } else {
                normalizedSamples.append(samples[i - 1] + samples[i] + samples[i - 1])
            }
        }
        
        return normalizedSamples
    }
}
