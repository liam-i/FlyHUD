//
//  KeyboardObserver.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by liam on 2024/1/24.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

#if os(iOS)
/// keyboard information model.
public struct KeyboardInfo {
    public enum Name {
        /// A event that posts immediately prior to a change in the keyboard’s frame.
        case willChangeFrame
        /// A event that posts immediately after a change in the keyboard’s frame.
        case didChangeFrame
    }

    /// The event name of the keyboard frame change.
    public let name: Name
    /// The duration of the keyboard animation in seconds.
    public let animationDuration: TimeInterval
    /// The animation curve that the system uses to animate the keyboard onto or off the screen.
    public let animationCurve: UInt
    /// The keyboard’s frame at the beginning of its animation.
    public let frameBegin: CGRect
    /// The keyboard’s frame at the end of its animation.
    public let frameEnd: CGRect

    /// A boolean value indicating whether the keyboard is visible.
    public let isVisible: Bool
}

/// A keyboard observer that tracks the keyboard’s position in your app’s layout.
@MainActor public protocol KeyboardObservable: AnyObject {
    /// Tells observers that the keyboard frame is about to change or has changed.
    func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboardInfo: KeyboardInfo)
}

/// A keyboard observer that tracks the keyboard's position in your app's layout.
// @unchecked Sendable is required for Swift 5.9 strict concurrency mode;
// Swift 6 infers Sendable for @MainActor types automatically.
@MainActor public final class KeyboardObserver: @unchecked Sendable {
    /// Enable keyboard observation. This method is equivalent to `KeyboardObserver.shared`.
    public static func enable() {
        _ = KeyboardObserver.shared
    }

    /// The shared singleton keyboard observer object. Execute once to automatically enable keyboard observation.
    public static let shared = { KeyboardObserver() }()

    /// This property contains detailed information about the keyboard's animation, frame, and whether it is visible.
    public private(set) var keyboardInfo: KeyboardInfo?

    /// Adds a given object to the keyboard observer list.
    ///
    /// - Parameter observer: The object to add to the keyboard observer list.
    ///                       This object must implement the KeyboardObservable protocol.
    public func add(_ observer: KeyboardObservable) {
        lock.withLock { observers.add(observer) }
    }

    /// Removes a given object from the keyboard observer list.
    ///
    /// - Parameter observer: The object to remove from the keyboard observer list.
    ///                       This object must implement the KeyboardObservable protocol.
    public func remove(_ observer: KeyboardObservable) {
        lock.withLock { observers.remove(observer) }
    }

    // Defensive lock: all access is @MainActor-isolated so concurrent access cannot occur,
    // but the lock provides safety for Swift 5.9 strict concurrency mode where isolation
    // is not fully enforced at runtime.
    private let lock = UnfairLock()
    private var observers: NSHashTable<AnyObject> = .weakObjects()

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameChangeNotification),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardFrameChangeNotification),
            name: UIResponder.keyboardDidChangeFrameNotification,
            object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func keyboardFrameChangeNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let screenBounds: CGRect = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .screen.bounds
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.screen.bounds
            ?? CGRect(origin: .zero, size: frameEnd.size)

        let info = KeyboardInfo(
            name: notification.name == UIResponder.keyboardWillChangeFrameNotification ? .willChangeFrame : .didChangeFrame,
            animationDuration: userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.0,
            animationCurve: userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0,
            frameBegin: userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect ?? .zero,
            frameEnd: frameEnd,
            isVisible: frameEnd.minY < screenBounds.maxY
        )
        keyboardInfo = info

        let snapshot = lock.withLock {
            observers.allObjects.compactMap { $0 as? KeyboardObservable }
        }

        for observer in snapshot {
            observer.keyboardObserver(self, keyboardInfoWillChange: info)
        }
    }
}
#endif // os(iOS)
