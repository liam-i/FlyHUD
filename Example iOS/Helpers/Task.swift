//
//  Task.swift
//  Example iOS
//
//  Created by Liam on 2024/1/21.
//  Copyright © 2024 Liam. All rights reserved.
//

import UIKit
import FlyHUD

final class Task: NSObject, @unchecked Sendable {
    static let shared = Task()

    private static let _cancelLock = UnfairLock()
    private nonisolated(unsafe) static var _canceled: Bool = false
    private static var canceled: Bool {
        get { _cancelLock.withLock { _canceled } }
        set { _cancelLock.withLock { _canceled = newValue } }
    }

    static func cancelTask() {
        canceled = true
    }

    static func test(_ sec: UInt32 = 3, completion: @MainActor @Sendable @escaping () -> Void) {
        request(sec, completion: completion)
    }

    static func request(_ sec: UInt32 = 3, progress: (@MainActor @Sendable (Float) -> Void)? = nil, completion: @MainActor @Sendable @escaping () -> Void) {
        let us = sec * 1000 * 1000 / 100
        DispatchQueue.global().async {
            canceled = false

            // 模拟一个任务的完成进度
            var progressValue: Float = 0.0
            while progressValue < 1.0 {
                if canceled { break }

                progressValue += 0.01 // 1 / 0.01 = 100
                let value = progressValue

                /// 回到主线程刷新UI
                DispatchQueue.main.async {
                    progress?(value)
                }

                usleep(us) // Simulate by just waiting.
            }

            DispatchQueue.main.async(execute: completion)
        }
    }

    static func resume(_ progress: (Progress) -> Void, sec: UInt32 = 3, completion: @MainActor @Sendable @escaping () -> Void) {
        let parent = Progress(totalUnitCount: 100)
        progress(parent)

        let us = sec * 1000 * 1000 / 100
        DispatchQueue.global().async {
            while parent.fractionCompleted < 1.0 {
                if parent.isCancelled { break }
                parent.completedUnitCount += 1
                usleep(us)
            }
            DispatchQueue.main.async(execute: completion)
        }
    }

    static func requestMultiTask(_ progress: @MainActor @Sendable @escaping (Float) -> Void, completion: @MainActor @Sendable @escaping (UInt8) -> Void) {
        DispatchQueue.global().async {
            // activityIndicator mode
            sleep(2)
            // Switch to determinate mode
            DispatchQueue.main.async { completion(3) }

            var progressValue: Float = 0.0
            while progressValue < 1.0 {
                progressValue += 0.01
                let value = progressValue
                DispatchQueue.main.async { progress(value) }
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

    private nonisolated(unsafe) var progress: (@MainActor @Sendable (Float) -> Void)?
    private nonisolated(unsafe) var completion: (@MainActor @Sendable () -> Void)?
    static func download(_ progress: @MainActor @Sendable @escaping (Float) -> Void, completion: @MainActor @Sendable @escaping () -> Void) {
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
            Task.shared.progress = nil
            Task.shared.completion = nil
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            Task.shared.progress?(progress)
        }
    }
}
