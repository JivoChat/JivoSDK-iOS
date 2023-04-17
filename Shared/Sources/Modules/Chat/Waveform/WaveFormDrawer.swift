//
//  WaveFormDrawer.swift
//  App
//
//  Created by Yulia Popova on 07.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import UIKit
import Accelerate

final class WaveFormDrawer {
    
    static var shared = WaveFormDrawer()
    
    public func image(samples: [Float],
                      configuration: WaveformConfiguration) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(configuration.size, false, UIScreen.main.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        drawBackground(context, configuration)
        context.saveGState()
        drawGraph(samples, context, configuration)
        context.restoreGState()
        
        let graphImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return graphImage
    }
    
    private func drawBackground(_ context: CGContext,
                                _ configuration: WaveformConfiguration) {
        context.setFillColor(configuration.backgroundColor.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: configuration.size))
    }
    
    private func drawGraph(_ samples: [Float],
                           _ context: CGContext,
                           _ configuration: WaveformConfiguration) {
        let rect = CGRect(origin: CGPoint.zero, size: configuration.size)
        let rectHeight = rect.size.height
        let rectWidth = rect.size.width
        let yCenter = rectHeight / 2.0
        let path = CGMutablePath()
        context.setLineWidth(configuration.lineWidth)
        context.setLineCap(.round)
        
        let amountOfLines = Int((rectWidth + configuration.space) / (configuration.lineWidth + configuration.space))
        
        let sampleParts = normalize(samples.chunked(into: samples.count / amountOfLines))
        let localMaxes = sampleParts.compactMap { Double($0.reduce(0, +)) / Double($0.count) }
        let globalMax = localMaxes.max() ?? 0
        
        let defaultAmplitude = (configuration.pickToPickAmplitude - configuration.lineWidth) / 2
        
        for i in 0..<localMaxes.count {
            let ampliduteCoef = CGFloat(min(globalMax, localMaxes[i] / globalMax))
            let drawingAmplitudeUp = yCenter - defaultAmplitude * ampliduteCoef
            let drawingAmplitudeDown = yCenter + defaultAmplitude * ampliduteCoef
            
            let x = CGFloat(i) * (configuration.space + configuration.lineWidth) + configuration.lineWidth * 0.5
            
            path.move(
                to: CGPoint(
                    x: x,
                    y: drawingAmplitudeUp
                )
            )
            path.addLine(
                to: CGPoint(
                    x: x,
                    y: drawingAmplitudeDown
                )
            )
        }

        context.addPath(path)
        context.setStrokeColor(configuration.color.cgColor)
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
