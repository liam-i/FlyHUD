//
//  KeyboardObserver.swift
//  LPHUD
//
//  Created by liam on 2024/1/24.
//

import UIKit

public struct KeyboardInfo {
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

public protocol KeyboardObservable: AnyObject {
    func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboardInfo: KeyboardInfo)
}

/// A keyboard observer that tracks the keyboard’s position in your app’s layout.
public class KeyboardObserver {
    /// The shared singleton keyboard observer object.
    public static let shared = { KeyboardObserver() }()
    /// This property contains detailed information about the keyboard's animation, frame, and whether it is visible.
    public private(set) var keyboardInfo: KeyboardInfo?

    private var observers: NSHashTable<AnyObject> = .weakObjects()

    /// Adds a given object to the keyboard observer list.
    /// - Parameter observer: The object to add to the keyboard observer list. This object must implement the KeyboardObservable protocol.
    public func add(_ observer: KeyboardObservable) {
        observers.add(observer)
    }

    /// Removes a given object from the keyboard observer list.
    /// - Parameter observer: The object to remove from the keyboard observer list. This object must implement the KeyboardObservable protocol.
    public func remove(_ observer: KeyboardObservable) {
        observers.remove(observer)
    }

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameWillChange),
                                               name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func keyboardFrameWillChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let frameEnd = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let frameBegin = userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect ?? .zero
        let animationDuration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.0
        let animationCurve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0

        let info = KeyboardInfo(
            animationDuration: animationDuration,
            animationCurve: animationCurve,
            frameBegin: frameBegin,
            frameEnd: frameEnd,
            isVisible: frameEnd.minY < UIScreen.main.bounds.height
        )
        keyboardInfo = info

        print("keyboardFrameWillChange=\(info.isVisible ? "显示" : "隐藏"), \(frameEnd.minY), \(UIScreen.main.bounds.height), \(UIScreen.main.bounds.maxY)")

        let enumerator = observers.objectEnumerator()
        while case let observer as KeyboardObservable = enumerator.nextObject() {
            observer.keyboardObserver(self, keyboardInfoWillChange: info)
        }
    }
}
