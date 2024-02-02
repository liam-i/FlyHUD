//
//  DisplayLink.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by liam on 2024/1/29.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import Foundation
import QuartzCore

/// The methods adopted by the object that allows your app to synchronize its drawing to the refresh rate of the display.
public protocol DisplayLinkDelegate: AnyObject {
    /// Tells the delegate that the refreshing the screen only every frame draw.
    func updateScreenInDisplayLink()
}

/// A timer object that allows your app to synchronize its drawing to the refresh rate of the display.
///
/// - Note: application adds it to a run loop using the `add(to:.main, forMode:.default)` method.
public class DisplayLink {
    /// The shared singleton keyboard observer object.
    public static let shared = DisplayLink()

    /// If necessary create a display link with the id and block you specify.
    ///
    /// - Parameter delegate: An delegate the system notifies to update the screen.
    public func add(_ delegate: DisplayLinkDelegate) {
        delegates.add(delegate)

        guard displayLink == nil else { return }

        let displayLink = CADisplayLink(target: self, selector: #selector(onScreenUpdate))
        displayLink.add(to: .main, forMode: .default)
        self.displayLink = displayLink
    }

    /// Removes the display link from all run loop modes if necessary..
    ///
    /// - Parameter delegate: An delegate.
    public func remove(_ delegate: DisplayLinkDelegate) {
        delegates.remove(delegate)

        guard delegates.count == 0 || delegates.allObjects.isEmpty else { return }

        displayLink?.invalidate()
        displayLink = nil
    }

    @objc
    private func onScreenUpdate() {
        let enumerator = delegates.objectEnumerator()
        while case let delegate as DisplayLinkDelegate = enumerator.nextObject() {
            delegate.updateScreenInDisplayLink()
        }
    }

    private init() {}

    private var displayLink: CADisplayLink?
    private var delegates: NSHashTable<AnyObject> = .weakObjects()
}
