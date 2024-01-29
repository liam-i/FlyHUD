//
//  DisplayLink.swift
//  LPHUD
//
//  Created by liam on 2024/1/29.
//

import Foundation
import QuartzCore

extension DisplayLink {
    public struct Block: Hashable, Equatable {
        public typealias ID = Int

        public let id: ID
        public let block: () -> Void

        public init(id: ID, block: @escaping () -> Void) {
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

public class DisplayLink {
    public static let shared = DisplayLink()

    private init() {}

    private var displayLink: CADisplayLink?
    private var blocks: Set<Block> = []

    public func add(for id: Block.ID, block: @escaping () -> Void) {
        DispatchQueue.main.safeAsync { [self] in
            blocks.insert(.init(id: id, block: block))

            guard displayLink == nil else { return }

            let displayLink = CADisplayLink(target: self, selector: #selector(onScreenUpdate))
            displayLink.add(to: .main, forMode: .default)
            self.displayLink = displayLink
        }
    }

    public func remove(at id: Block.ID) {
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
