//
//  UnfairLock.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Liam on 2024/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import os

/// A lightweight unfair lock wrapper providing scoped locking via `withLock`.
///
/// This is essentially a backport of Swift 6's `Mutex` for iOS 13+ targets.
/// UIKit objects using this lock are guaranteed to be accessed from the main thread,
/// but the lock protects shared state accessed from multiple execution contexts.
///
/// - Note: `os_unfair_lock` does not support recursive locking. Attempting to
///   acquire the lock from a thread that already holds it will deadlock.
public final class UnfairLock: @unchecked Sendable {
    private let _lock: os_unfair_lock_t

    public init() {
        _lock = .allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    deinit {
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }

    /// Executes the given closure while holding the lock.
    ///
    /// - Parameter body: A closure to execute while the lock is held.
    /// - Returns: The value returned by `body`.
    /// - Throws: Rethrows any error thrown by `body`.
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        os_unfair_lock_lock(_lock)
        defer { os_unfair_lock_unlock(_lock) }
        return try body()
    }
}
