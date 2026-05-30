//
//  UnfairLockTests.swift
//  HUD <https://github.com/liam-i/FlyHUD>
//
//  Created by Tests Generator on 2025/8/18.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import XCTest
@testable import FlyHUD

private final class Box<T: Sendable>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

final class UnfairLockTests: XCTestCase {

    // MARK: - Initialization

    func testInitialization() {
        let lock = UnfairLock()
        XCTAssertNotNil(lock, "UnfairLock should be initialized")
    }

    // MARK: - Basic Locking

    func testWithLockReturnsValue() {
        let lock = UnfairLock()
        let result = lock.withLock { 42 }
        XCTAssertEqual(result, 42, "withLock should return the closure's return value")
    }

    func testWithLockReturnsString() {
        let lock = UnfairLock()
        let result = lock.withLock { "hello" }
        XCTAssertEqual(result, "hello")
    }

    func testWithLockReturnsVoid() {
        let lock = UnfairLock()
        var mutated = false
        lock.withLock { mutated = true }
        XCTAssertTrue(mutated, "withLock should execute the closure")
    }

    func testWithLockRethrowsError() {
        let lock = UnfairLock()
        struct TestError: Error {}

        XCTAssertThrowsError(try lock.withLock { throw TestError() }) { error in
            XCTAssertTrue(error is TestError, "withLock should rethrow the closure's error")
        }
    }

    // MARK: - Thread Safety

    func testConcurrentAccess() {
        let lock = UnfairLock()
        let counter = Box(0)
        let iterations = 1000
        let expectation = expectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = iterations

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        for _ in 0..<iterations {
            queue.async {
                lock.withLock { counter.value += 1 }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(counter.value, iterations, "Counter should equal iterations after concurrent increments")
    }

    func testConcurrentReadWrite() {
        let lock = UnfairLock()
        let array = Box<[Int]>([])
        let writeCount = 500
        let expectation = expectation(description: "Concurrent read/write")
        expectation.expectedFulfillmentCount = writeCount * 2

        let queue = DispatchQueue(label: "test.concurrent.rw", attributes: .concurrent)

        for i in 0..<writeCount {
            queue.async {
                lock.withLock { array.value.append(i) }
                expectation.fulfill()
            }
            queue.async {
                _ = lock.withLock { array.value.count }
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(array.value.count, writeCount)
    }

    // MARK: - Multiple Instances

    func testMultipleLocksAreIndependent() {
        let lock1 = UnfairLock()
        let lock2 = UnfairLock()
        var value1 = 0
        var value2 = 0

        lock1.withLock { value1 = 1 }
        lock2.withLock { value2 = 2 }

        XCTAssertEqual(value1, 1)
        XCTAssertEqual(value2, 2)
    }

    // MARK: - Performance

    func testLockPerformance() {
        let lock = UnfairLock()
        var counter = 0

        measure {
            for _ in 0..<10000 {
                lock.withLock { counter += 1 }
            }
        }
    }
}
