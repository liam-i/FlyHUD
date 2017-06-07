//
//  ViewController.swift
//  Example
//
//  Created by 李鹏 on 2017/6/1.
//  Copyright © 2017年 Zhejiang lp Technology Co., Ltd. All rights reserved.
//

import UIKit
import LPProgressHUD

struct LPHUDModel {
    var title: String
    var selector: Selector
}

class LPHUDViewController: UITableViewController {
    
    lazy var examples: [[LPHUDModel]] = [
        [LPHUDModel(title: "Indeterminate mode", selector: #selector(indeterminateExample)),
         LPHUDModel(title: "With label", selector: #selector(labelExample)),
         LPHUDModel(title: "With details label", selector: #selector(detailsLabelExample))
        ],
        [LPHUDModel(title: "Determinate mode", selector: #selector(determinateExample)),
         LPHUDModel(title: "Annular determinate mode", selector: #selector(annularDeterminateExample)),
         LPHUDModel(title: "Bar determinate mode", selector: #selector(barDeterminateExample))
        ],
        [LPHUDModel(title: "Text only", selector: #selector(textExample)),
         LPHUDModel(title: "Custom view", selector: #selector(customViewExample)),
         LPHUDModel(title: "With action button", selector: #selector(cancelationExample)),
         LPHUDModel(title: "Mode switching", selector: #selector(modeSwitchingExample))
        ],
        [LPHUDModel(title: "On window", selector: #selector(windowExample)),
         LPHUDModel(title: "URLSession", selector: #selector(networkingExample)),
         LPHUDModel(title: "Determinate with Progress", selector: #selector(determinateProgressExample)),
         LPHUDModel(title: "Dim background", selector: #selector(dimBackgroundExample)),
         LPHUDModel(title: "Colored", selector: #selector(colorExample))
        ]
    ]
    lazy var canceled: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundView = UIImageView(image: UIImage(named: "bg.jpg"))
                
    }
}

// MARK: - Examples

extension LPHUDViewController {
    
    func indeterminateExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        // 模仿一个异步任务
        DispatchQueue.global().async {
            self.doSomeWork() // 异步任务需要耗时3s
            // 回到主线程
            DispatchQueue.main.sync {
                hud.hide(animated: true)
            }
        }
    }
    
    func labelExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "加载中..."
        DispatchQueue.global().async {
            self.doSomeWork()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func detailsLabelExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "加载中..."
        hud.detailsLabel.text = "正在进行网络请求\n(1/1)"
        DispatchQueue.global().async {
            self.doSomeWork()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func determinateExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinate
        hud.detailsLabel.text = "加载中..."
        DispatchQueue.global().async {
            self.doSomeWorkWithProgress() // 模拟一个加载进度的任务
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func annularDeterminateExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.mode = .annularDeterminate
        hud.label.text = "加载中..."
        DispatchQueue.global().async {
            self.doSomeWorkWithProgress()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func barDeterminateExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinateHorizontalBar
        hud.label.text = "加载中..."
        DispatchQueue.global().async {
            self.doSomeWorkWithProgress()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func textExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.mode = .text
        hud.label.text = "密码错误"
        hud.offset = CGPoint(x: 0.0, y: LPProgressMaxOffset) // 移动到底部居中
        hud.hide(animated: true, afterDelay: 3.0)
    }
    
    func customViewExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.mode = .customView
        hud.customView = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
        hud.isSquare = true
        hud.label.text = "完成"
        hud.hide(animated: true, afterDelay: 3.0)
    }
    
    func cancelationExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinate
        hud.label.text = "加载中..."
        hud.button.setTitle("取消", for: .normal)
        hud.button.addTarget(self, action: #selector(cancelWork), for: .touchUpInside)
        
        DispatchQueue.global().async {
            self.doSomeWorkWithProgress()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func modeSwitchingExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "准备中..."
        hud.minSize = CGSize(width: 150.0, height: 100.0)
        DispatchQueue.global().async {
            self.doSomeWorkWithMixedProgress()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func windowExample() {
        let hud = LPProgressHUD.show(to: view.window!, animated: true)
        DispatchQueue.global().async {
            self.doSomeWork()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func networkingExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.label.text = "准备中..."
        hud.minSize = CGSize(width: 150.0, height: 100.0)
        doSomeNetworkWorkWithProgress()
    }
    
    func determinateProgressExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.mode = .determinate
        hud.label.text = "加载中..."
        let progress = Progress(totalUnitCount: 100)
        hud.progressObject = progress
        hud.button.setTitle("取消", for: .normal)
        hud.button.addTarget(progress, action: #selector(Progress.cancel), for: .touchUpInside)
        DispatchQueue.global().async {
            self.doSomeWork(with: progress)
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func dimBackgroundExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.backgroundView.style = .solidColor
        hud.backgroundView.color = UIColor(white: 0.0, alpha: 0.1)
        DispatchQueue.global().async {
            self.doSomeWork()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
    
    func colorExample() {
        let hud = LPProgressHUD.show(to: navigationController!.view, animated: true)
        hud.contentColor = UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1.0)
        hud.label.text = "加载中..."
        DispatchQueue.global().async {
            self.doSomeWork()
            DispatchQueue.main.async {
                hud.hide(animated: true)
            }
        }
    }
}

// MARK: - Tasks

extension LPHUDViewController {
    
    func doSomeWork() {
        sleep(3) // 模拟一个任务，需要耗时3s
    }
    
    func doSomeWorkWithProgress() {
        canceled = false
        
        // 模拟一个任务的完成进度
        var progress: CGFloat = 0.0
        while progress < 1.0 {
            if canceled { break }
            
            progress += 0.01
            
            /// 回到主线程刷新UI
            DispatchQueue.main.async {
                LPProgressHUD.hud(for: self.navigationController!.view)?.progress = progress
            }
            
            usleep(50000)
        }
    }
    
    func doSomeWork(with progress: Progress) {
        // 模拟一个任务的完成进度
        while progress.fractionCompleted < 1.0 {
            if progress.isCancelled { break }
            
            progress.becomeCurrent(withPendingUnitCount: 1)
            progress.resignCurrent()
            
            usleep(50000)
        }
    }
    
    func doSomeWorkWithMixedProgress() {
        guard let hud = LPProgressHUD.hud(for: navigationController!.view) else { return }
        
        // Indeterminate mode
        sleep(2)
        
        // Switch to determinate mode
        DispatchQueue.main.async {
            hud.mode = .determinate
            hud.label.text = "加载中..."
        }
        
        var progress: CGFloat = 0.0
        while progress < 1.0 {
            progress += 0.01
            DispatchQueue.main.async {
                hud.progress = progress
            }
            usleep(50000)
        }
        
        // Back to indeterminate mode
        DispatchQueue.main.async {
            hud.mode = .indeterminate
            hud.label.text = "清理中..."
        }
        
        sleep(2)
        
        DispatchQueue.main.async {
            hud.customView = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
            hud.mode = .customView
            hud.label.text = "已完成"
        }
        sleep(2)
    }
    
    func doSomeNetworkWorkWithProgress() {
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        if let url = URL(string: "https://support.apple.com/library/APPLE/APPLECARE_ALLGEOS/HT1425/sample_iPod.m4v.zip") {
            let task = session.downloadTask(with: url)
            task.resume()
        }
    }
    
    func cancelWork(_ sender: UIButton) {
        canceled = true
    }
}

// MARK: - URLSessionDelegate

extension LPHUDViewController: URLSessionDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 用加载的数据做一些事情...
        
        // 回到主线程更新UI
        DispatchQueue.main.async {
            guard let hud = LPProgressHUD.hud(for: self.navigationController!.view) else { return }
            hud.customView = UIImageView(image: UIImage(named: "Checkmark")?.withRenderingMode(.alwaysTemplate))
            hud.mode = .customView
            hud.label.text = "已完成"
            hud.hide(animated: true, afterDelay: 3.0)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
        
        // 回到主线程更新UI
        DispatchQueue.main.async {
            guard let hud = LPProgressHUD.hud(for: self.navigationController!.view) else { return }
            hud.mode = .determinate
            hud.progress = progress
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension LPHUDViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return examples.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return examples[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LPHUDExampleCell", for: indexPath)
        cell.textLabel?.text = examples[indexPath.section][indexPath.row].title
        
        cell.selectedBackgroundView = UIView()
        cell.selectedBackgroundView?.backgroundColor = cell.textLabel?.textColor.withAlphaComponent(0.1)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        perform(examples[indexPath.section][indexPath.row].selector)
    }
    
}
