//
//  WaveformSamplesExtractor.swift
//  App
//
//  Created by Yulia Popova on 07.02.2023.
//  Copyright © 2023 JivoSite. All rights reserved.
//

import Foundation
import AVFoundation
import Accelerate

final class WaveformSamplesExtractor {
    
    static let shared = WaveformSamplesExtractor()
    
    private var outputSettings: [String : Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsNonInterleaved: false
    ]
    public static var noiseFloor = Float(-50.0)
    
    public func samples(audioTrack: AVAssetTrack,
        desiredNumberOfSamples: Int = 300,
        onSuccess: @escaping (_ samples: [Float], _ sampleMax: Float,_ identifier: String?) -> (),
        onFailure: @escaping () -> (),
        identifiedBy: String? = nil) {
            do {
                guard let asset = audioTrack.asset else { return }
                let assetReader = try AVAssetReader(asset: asset)
                
                guard audioTrack.mediaType == .audio else { return }
                
                let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
                assetReader.add(trackOutput)
                
                extract(
                    samplesFrom: assetReader,
                    asset: assetReader.asset,
                    track: audioTrack,
                    downsampledTo: desiredNumberOfSamples,
                    onSuccess: {samples, sampleMax in
                        switch assetReader.status {
                        case .completed:
                            onSuccess(self.normalize(samples), sampleMax, identifiedBy)
                        default:
                            onFailure()
                        }
                    }, onFailure: {
                        onFailure()
                    })
            } catch {
                onFailure()
            }
        }

    private func extract(samplesFrom reader: AVAssetReader,
                                      asset: AVAsset,
                                      track:AVAssetTrack,
                                      downsampledTo desiredNumberOfSamples: Int,
                                      onSuccess: @escaping (_ samples: [Float], _ sampleMax: Float) -> (),
                                      onFailure: @escaping () -> ()) {
        
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            switch status {
            case .loaded:
                guard
                    let formatDescriptions = track.formatDescriptions as? [CMAudioFormatDescription],
                    let audioFormatDesc = formatDescriptions.first,
                    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
                else { break }
                
                var sampleMax: Float = -Float.infinity
                
                let positiveInfinity = CMTime.positiveInfinity
                
                let duration: Double = (reader.timeRange.duration == positiveInfinity) ? Double(asset.duration.value) : Double(reader.timeRange.duration.value)
                let timscale: Double = (reader.timeRange.duration == positiveInfinity) ? Double(asset.duration.timescale) : Double(reader.timeRange.start.timescale)
                
                let numOfTotalSamples = (asbd.pointee.mSampleRate) * duration / timscale
                
                var channelCount = 1
                
                let formatDesc = track.formatDescriptions
                for item in formatDesc {
                    guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item as! CMAudioFormatDescription) else { continue }
                    channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
                }
                
                let samplesPerPixel = Int(max(1, Double(channelCount) * numOfTotalSamples / Double(desiredNumberOfSamples)))
                let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
                
                var outputSamples = [Float]()
                var sampleBuffer = Data()
                
                reader.startReading()
                
                while reader.status == .reading {
                    guard let readSampleBuffer = reader.outputs[0].copyNextSampleBuffer(),
                          let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                        break
                    }
                    
                    var readBufferLength = 0
                    
                    var readBufferPointer: UnsafeMutablePointer<Int8>?
                    CMBlockBufferGetDataPointer(readBuffer, atOffset: 0, lengthAtOffsetOut: &readBufferLength, totalLengthOut: nil, dataPointerOut: &readBufferPointer)
                    sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
                    CMSampleBufferInvalidate(readSampleBuffer)
                    
                    let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
                    let downSampledLength = (totalSamples / samplesPerPixel)
                    let samplesToProcess = downSampledLength * samplesPerPixel
                    
                    guard samplesToProcess > 0 else { continue }
                    
                    self.processSamples(fromData: &sampleBuffer,
                                         sampleMax: &sampleMax,
                                         outputSamples: &outputSamples,
                                         samplesToProcess: samplesToProcess,
                                         downSampledLength: downSampledLength,
                                         samplesPerPixel: samplesPerPixel,
                                         filter: filter)
                }
                
                let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
                if samplesToProcess > 0 {
                    let downSampledLength = 1
                    let samplesPerPixel = samplesToProcess
                    
                    let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
                    
                    self.processSamples(
                        fromData: &sampleBuffer,
                        sampleMax: &sampleMax,
                        outputSamples: &outputSamples,
                        samplesToProcess: samplesToProcess,
                        downSampledLength: downSampledLength,
                        samplesPerPixel: samplesPerPixel,
                        filter: filter)
                }
                DispatchQueue.main.async {
                    onSuccess(outputSamples, sampleMax)
                }
                return
                
            case .failed, .cancelled, .loading, .unknown:
                DispatchQueue.main.async {
                    onFailure()
                }
            @unknown default:
                DispatchQueue.main.async {
                    onFailure()
                }
            }
        }
    }
    
    private func processSamples(fromData sampleBuffer: inout Data,
                                        sampleMax: inout Float,
                                        outputSamples: inout [Float],
                                        samplesToProcess: Int,
                                        downSampledLength: Int,
                                        samplesPerPixel: Int,
                                        filter: [Float]) {
        sampleBuffer.withUnsafeBytes { (samples: UnsafePointer<Int16>) in
            
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            
            let sampleCount = vDSP_Length(samplesToProcess)
            vDSP_vflt16(samples, 1, &processingBuffer, 1, sampleCount)
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
            
            var zero: Float = 32768.0
            vDSP_vdbcon(processingBuffer, 1, &zero, &processingBuffer, 1, sampleCount, 1)
            
            var ceil: Float = 0.0
            var noiseFloorFloat = WaveformSamplesExtractor.noiseFloor
            vDSP_vclip(processingBuffer, 1, &noiseFloorFloat, &ceil, &processingBuffer, 1, sampleCount)
            
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            
            for element in downSampledData {
                if element > sampleMax { sampleMax = element }
            }
            
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
            outputSamples += downSampledData
        }
    }
    
    private func normalize(_ samples: [Float]) -> [Float] {
        let min = samples.min() ?? 0
        return samples.map { $0 - min }
    }
}
