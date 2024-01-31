//
//  KeyboardObserver.swift
//  LPHUD
//
//  Created by liam on 2024/1/24.
//

import UIKit

#if !os(tvOS)
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
public protocol KeyboardObservable: AnyObject {
    /// Tells observers that the keyboard frame is about to change or has changed.
    func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboardInfo: KeyboardInfo)
}

/// A keyboard observer that tracks the keyboard’s position in your app’s layout.
public class KeyboardObserver {
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
        observers.add(observer)
    }

    /// Removes a given object from the keyboard observer list.
    /// - Parameter observer: The object to remove from the keyboard observer list.
    ///                       This object must implement the KeyboardObservable protocol.
    public func remove(_ observer: KeyboardObservable) {
        observers.remove(observer)
    }

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

        let info = KeyboardInfo(
            name: notification.name == UIResponder.keyboardWillChangeFrameNotification ? .willChangeFrame : .didChangeFrame,
            animationDuration: userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.0,
            animationCurve: userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0,
            frameBegin: userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect ?? .zero,
            frameEnd: frameEnd,
            isVisible: frameEnd.minY < UIScreen.main.bounds.maxY
        )
        keyboardInfo = info

        let enumerator = observers.objectEnumerator()
        while case let observer as KeyboardObservable = enumerator.nextObject() {
            observer.keyboardObserver(self, keyboardInfoWillChange: info)
        }
    }
}
#endif
