//
//  Task.swift
//  HUD_Example
//
//  Created by Liam on 2024/1/21.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import UIKit

class Task: NSObject {
    static let shared = Task()
    static private var canceled: Bool = false

    static func cancelTask() {
        Task.canceled = true
    }

    static func test(_ sec: UInt32 = 3, completion: @escaping () -> Void) {
        request(sec, completion: completion)
    }

    static func request(_ sec: UInt32 = 3, progress: ((Float) -> Void)? = nil, completion: @escaping () -> Void) {
        let us = sec * 1000 * 1000 / 100
        DispatchQueue.global().async {
            canceled = false

            // 模拟一个任务的完成进度
            var progressValue: Float = 0.0
            while progressValue < 1.0 {
                if canceled { break }

                progressValue += 0.01 // 1 / 0.01 = 100

                /// 回到主线程刷新UI
                DispatchQueue.main.async {
                    progress?(progressValue)
                }

                usleep(us) // Simulate by just waiting.
            }

            DispatchQueue.main.async(execute: completion)
        }
    }

    static func resume(with progress: Progress, sec: UInt32 = 3, completion: @escaping () -> Void) {
        let us = sec * 1000 * 1000 / 100
        DispatchQueue.global().async {
            while progress.fractionCompleted < 1.0 {
                if progress.isCancelled { break }

                progress.becomeCurrent(withPendingUnitCount: 1)
                progress.resignCurrent()

                usleep(us)
            }

            DispatchQueue.main.async(execute: completion)
        }
    }

    static func requestMultiTask(_ progress: @escaping (Float) -> Void, completion: @escaping (UInt8) -> Void) {
        DispatchQueue.global().async {
            // activityIndicator mode
            sleep(2)
            // Switch to determinate mode
            DispatchQueue.main.async { completion(3) }

            var progressValue: Float = 0.0
            while progressValue < 1.0 {
                progressValue += 0.01
                DispatchQueue.main.async { progress(progressValue) }
                usleep(50000)
            }

            // Back to activityIndicator mode
            DispatchQueue.main.async { completion(2) }

            sleep(2)
            DispatchQueue.main.async { completion(1) }

            sleep(2)
            DispatchQueue.main.async { completion(0) }
        }
    }

    private var progress: ((Float) -> Void)?
    private var completion: (() -> Void)?
    static func download(_ progress: @escaping (Float) -> Void, completion: @escaping () -> Void) {
        shared.progress = progress
        shared.completion = completion

        let url = URL(string: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip")!
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: shared, delegateQueue: nil)
        session.downloadTask(with: url).resume()
    }
}

extension Task: URLSessionDelegate, URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async {
            Task.shared.completion?()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            Task.shared.progress?(progress)
        }
    }
}
