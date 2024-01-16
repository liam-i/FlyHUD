//
//  Model.swift
//  HUD_Example
//
//  Created by liam on 2021/7/9.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit

struct Model {
    let title: String
    let selector: Selector
}

extension Model {
    static var examples: [[Model]] {[
        [Model(title: "Indeterminate mode", selector: #selector(ViewController.indeterminateExample)),
         Model(title: "With label", selector: #selector(ViewController.labelExample)),
         Model(title: "With details label", selector: #selector(ViewController.detailsLabelExample))
        ],
        [Model(title: "Determinate mode", selector: #selector(ViewController.determinateExample)),
         Model(title: "Annular determinate mode", selector: #selector(ViewController.annularDeterminateExample)),
         Model(title: "Bar determinate mode", selector: #selector(ViewController.barDeterminateExample))
        ],
        [Model(title: "Text only", selector: #selector(ViewController.textExample)),
         Model(title: "Custom view", selector: #selector(ViewController.customViewExample)),
         Model(title: "Custom Progress view", selector: #selector(ViewController.customProgressViewExample))
        ],
        [Model(title: "With action button", selector: #selector(ViewController.cancelationExample)),
         Model(title: "Mode switching", selector: #selector(ViewController.modeSwitchingExample))
        ],
        [Model(title: "On window", selector: #selector(ViewController.windowExample)),
         Model(title: "URLSession", selector: #selector(ViewController.networkingExample)),
         Model(title: "Determinate with Progress", selector: #selector(ViewController.determinateProgressExample)),
         Model(title: "Dim background", selector: #selector(ViewController.dimBackgroundExample)),
         Model(title: "Colored", selector: #selector(ViewController.colorExample))
        ],
        [Model(title: "Multiple HUD", selector: #selector(ViewController.multipleHUDExample))]
    ]}
}

// MARK: Tasks

class Task: NSObject {
    private static var canceled: Bool = false

    static func cancelTask() {
        canceled = true
    }

    static func test(_ sec: UInt32 = 3, completion: @escaping () -> Void) {
        request(sec, completion: completion)
    }

    static func request(_ sec: UInt32 = 3, completion: @escaping () -> Void) {
        DispatchQueue.global().async {
            sleep(sec) // Simulate by just waiting.
            DispatchQueue.main.async(execute: completion)
        }
    }

    static func request(_ sec: UInt32 = 3, progress: @escaping (CGFloat) -> Void, completion: @escaping () -> Void) {
        let us = sec * 1000 * 1000 / 100
        DispatchQueue.global().async {
            canceled = false

            // 模拟一个任务的完成进度
            var progressValue: CGFloat = 0.0
            while progressValue < 1.0 {
                if canceled { break }

                progressValue += 0.01 // 1 / 0.01 = 100

                /// 回到主线程刷新UI
                DispatchQueue.main.async {
                    progress(progressValue)
                }

                usleep(us)
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

    static func requestMultiTask(_ progress: @escaping (CGFloat) -> Void, completion: @escaping (UInt8) -> Void) {
        DispatchQueue.global().async {
            // Indeterminate mode
            sleep(2)

            // Switch to determinate mode
            DispatchQueue.main.async {
                completion(3)
            }

            var progressValue: CGFloat = 0.0
            while progressValue < 1.0 {
                progressValue += 0.01
                DispatchQueue.main.async {
                    progress(progressValue)
                }
                usleep(50000)
            }

            // Back to indeterminate mode
            DispatchQueue.main.async {
                completion(2)
            }

            sleep(2)

            DispatchQueue.main.async {
                completion(1)
            }
            sleep(2)

            DispatchQueue.main.async {
                completion(0)
            }
        }
    }

    private static let shared = { Task() }()
    private var progress: ((CGFloat) -> Void)?
    private var completion: (() -> Void)?
    static func download(_ progress: @escaping (CGFloat) -> Void, completion: @escaping () -> Void) {
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
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        print("download progress: \(progress)")

        DispatchQueue.main.async {
            Task.shared.progress?(progress)
        }
    }
}
