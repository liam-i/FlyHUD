//
//  KeyboardObserver.swift
//  LPHUD
//
//  Created by liam on 2024/1/24.
//

import UIKit

public struct KeyboardInfo {
    /// The duration of the keyboard animation in seconds.
    public var animationDuration: TimeInterval = 0.0
    /// The animation curve that the system uses to animate the keyboard onto or off the screen.
    public var animationCurve: UInt = 0
    /// The keyboard’s frame at the beginning of its animation.
    public var frameBegin: CGRect = .zero
    /// The keyboard’s frame at the end of its animation.
    public var frameEnd: CGRect = .zero

    /// A boolean value indicating whether the keyboard is visible.
    public var isVisible: Bool = false
}

public protocol KeyboardObservable: AnyObject {
    func keyboardObserver(_ keyboardObserver: KeyboardObserver, keyboardInfoWillChange keyboard: KeyboardInfo)
}

public class KeyboardObserver {
    public static let shared = { KeyboardObserver() }()
    public private(set) var keyboardInfo = KeyboardInfo()

    private var observers: NSHashTable<AnyObject> = .weakObjects()

    public func add(_ observer: KeyboardObservable) {
        observers.add(observer)
    }

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

        let enumerator = observers.objectEnumerator()
        while case let observer as KeyboardObservable = enumerator.nextObject() {
            observer.keyboardObserver(self, keyboardInfoWillChange: info)
        }
    }
}
