//
//  DisplayLink.swift
//  LPHUD
//
//  Created by liam on 2024/1/29.
//

import Foundation
import QuartzCore

extension DisplayLink {
    public typealias TargetID = Int

    public struct Block: Hashable, Equatable {
        public let id: TargetID
        public let block: () -> Void

        public init(id: TargetID, block: @escaping () -> Void) {
            self.id = id
            self.block = block
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        public static func == (lhs: DisplayLink.Block, rhs: DisplayLink.Block) -> Bool {
            lhs.id == rhs.id
        }
    }
}

/// A timer object that allows your app to synchronize its drawing to the refresh rate of the display.
/// - Note: application adds it to a run loop using the `add(to:.main, forMode:.default)` method.
public class DisplayLink {
    /// The shared singleton keyboard observer object.
    public static let shared = DisplayLink()

    private init() {}

    private var displayLink: CADisplayLink?
    private var blocks: Set<Block> = []

    /// If necessary create a display link with the id and block you specify.
    /// - Parameters:
    ///   - id: An target id the system notifies to update the screen.
    ///   - block: The block to call on the target.
    public func add(for id: TargetID, block: @escaping () -> Void) {
        DispatchQueue.main.safeAsync { [self] in
            blocks.insert(.init(id: id, block: block))

            guard displayLink == nil else { return }

            let displayLink = CADisplayLink(target: self, selector: #selector(onScreenUpdate))
            displayLink.add(to: .main, forMode: .default)
            self.displayLink = displayLink
        }
    }

    /// Removes the display link from all run loop modes if necessary..
    /// - Parameter id: An target id.
    public func remove(at id: TargetID) {
        DispatchQueue.main.safeAsync { [self] in
            if let index = blocks.firstIndex(where: { $0.id == id }) {
                blocks.remove(at: index)
            }

            if blocks.isEmpty {
                displayLink?.invalidate()
                displayLink = nil
            }
        }
    }

    @objc
    private func onScreenUpdate() {
        blocks.forEach { $0.block() }
    }
}
