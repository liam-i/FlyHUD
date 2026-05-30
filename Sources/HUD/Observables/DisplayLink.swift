//
//  DisplayLink.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by liam on 2024/1/29.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// The methods adopted by the object that allows your app to synchronize its drawing to the refresh rate of the display.
@MainActor public protocol DisplayLinkDelegate: AnyObject {
    /// Tells the delegate to refresh the screen once per frame draw.
    func updateScreenInDisplayLink()
}

/// A timer object that allows your app to synchronize its drawing to the refresh rate of the display.
///
/// - Note: The display link is added to the main run loop using `add(to:.main, forMode:.default)`.
// @unchecked Sendable is required for Swift 5.9 strict concurrency mode;
// Swift 6 infers Sendable for @MainActor types automatically.
@MainActor public final class DisplayLink: @unchecked Sendable {
    /// The shared singleton display link object.
    public static let shared = DisplayLink()

    /// Adds a delegate to receive display link callbacks. Creates the display link if it doesn't exist yet.
    ///
    /// - Parameter delegate: A delegate the system notifies to update the screen.
    public func add(_ delegate: DisplayLinkDelegate) {
        lock.withLock {
            delegates.add(delegate)
        }

        guard displayLink == nil else { return }

        let proxy = DisplayLinkProxy(self)
        let displayLink = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.onScreenUpdate(_:)))
        displayLink.add(to: .main, forMode: .default)
        self.displayLink = displayLink
    }

    /// Removes a delegate from display link callbacks. Invalidates the display link if no delegates remain.
    ///
    /// - Parameter delegate: A delegate to remove.
    public func remove(_ delegate: DisplayLinkDelegate) {
        lock.withLock {
            delegates.remove(delegate)
        }

        guard delegates.allObjects.isEmpty else { return }

        displayLink?.invalidate()
        displayLink = nil
    }

    fileprivate func onScreenUpdate() {
        let snapshot = lock.withLock {
            delegates.allObjects.compactMap { $0 as? DisplayLinkDelegate }
        }

        for delegate in snapshot {
            delegate.updateScreenInDisplayLink()
        }
    }

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        // Singleton - never deallocated in practice.
    }

    @objc
    private func applicationDidEnterBackground() {
        displayLink?.isPaused = true
    }

    @objc
    private func applicationWillEnterForeground() {
        displayLink?.isPaused = false
    }

    // Defensive lock: all access is @MainActor-isolated so concurrent access cannot occur,
    // but the lock provides safety for Swift 5.9 strict concurrency mode where isolation
    // is not fully enforced at runtime.
    private let lock = UnfairLock()
    private var displayLink: CADisplayLink?
    private var delegates: NSHashTable<AnyObject> = .weakObjects()
}

// MARK: - DisplayLinkProxy

/// A weak proxy that breaks the CADisplayLink → DisplayLink retain cycle.
@MainActor private class DisplayLinkProxy {
    weak var target: DisplayLink?

    init(_ target: DisplayLink) {
        self.target = target
    }

    @objc func onScreenUpdate(_ displayLink: CADisplayLink) {
        target?.onScreenUpdate()
    }
}
