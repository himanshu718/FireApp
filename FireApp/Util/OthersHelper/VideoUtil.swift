//
//  VideoUtil.swift
//  FireApp
//
//  Created by Devlomi on 7/27/19.
//  Copyright © 2019 Devlomi. All rights reserved.
//
import AVFoundation
import UIKit
import RxSwift

class VideoUtil {
    static func generateThumbnail(path: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            return nil
        }
    }

    static func exportAsMp4(inputUrl: URL, outputUrl: URL, completionHandler handler: @escaping () -> Void) {
        let avAsset = AVURLAsset.init(url: inputUrl, options: nil)


        let exporter = AVAssetExportSession(asset: avAsset,
            presetName: AVAssetExportPresetMediumQuality)!
        exporter.outputURL = outputUrl
        exporter.outputFileType = AVFileType.mp4
        exporter.shouldOptimizeForNetworkUse = true
        exporter.exportAsynchronously {
            handler()
        }
    }


    static func exportAsMp4Observable(inputUrl: URL, outputUrl: URL,_ deleteSourceUrlOnComplete:Bool = false) -> Observable<URL> {
        return Observable<URL>.create { (observable) -> Disposable in
            let avAsset = AVURLAsset.init(url: inputUrl, options: nil)

            let exporter = AVAssetExportSession(asset: avAsset,
                presetName: AVAssetExportPresetMediumQuality)!
            exporter.outputURL = outputUrl
            exporter.outputFileType = AVFileType.mp4
            exporter.shouldOptimizeForNetworkUse = true
            exporter.exportAsynchronously {
                if deleteSourceUrlOnComplete{
                    let fileManager = FileManager.default
                    try? fileManager.removeItem(at: inputUrl)
                }
                observable.onNext(outputUrl)
                observable.onCompleted()

            }
            return Disposables.create()
        }

    }
}
