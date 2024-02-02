//
//  HUDExtended.swift
//  HUD <https://github.com/liam-i/HUD>
//
//  Created by Liam on 2024/1/27.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

import UIKit

/// Type that acts as a generic extension point for all `HUDExtended` types.
public struct HUDExtension<ExtendedType> {
    /// Stores the type or meta-type of any extended type.
    private var type: ExtendedType
    /// Create an instance from the provided value.
    /// - Parameter type: Instance being extended.
    public init(_ type: ExtendedType) {
        self.type = type
    }
}

/// Protocol describing the `h` extension points for HUD extended types.
public protocol HUDExtended {
    /// Type being extended.
    associatedtype ExtendedType
    /// Static HUD extension point.
    static var h: HUDExtension<ExtendedType>.Type { get set }
    /// Instance HUD extension point.
    var h: HUDExtension<ExtendedType> { get set }
}
extension HUDExtended {
    /// Static HUD extension point.
    public static var h: HUDExtension<Self>.Type {
        get { HUDExtension<Self>.self }
        set {}
    }
    /// Instance HUD extension point.
    public var h: HUDExtension<Self> {
        get { HUDExtension(self) }
        set {}
    }
}

extension Optional: HUDExtended {}
extension Float: HUDExtended {}
extension Bool: HUDExtended {}
extension CGRect: HUDExtended {}
extension CGPoint: HUDExtended {}
extension CGFloat: HUDExtended {}
extension NSObject: HUDExtended {}

extension HUDExtension where ExtendedType == UIColor {
    /// Defaults to `UIColor.label.withAlphaComponent(0.7)` on iOS 13
    /// and later and. `UIColor(white: 0.0, alpha: 0.7)` on older systems.
    public static let content: UIColor = {
        if #available(iOS 13.0, tvOS 13.0, *) {
            return UIColor.label.withAlphaComponent(0.7)
        } else {
            return UIColor(white: 0.0, alpha: 0.7)
        }
    }()

    /// The background color or the blur tint color. Defaults to `nil` on iOS 13
    /// and later and. `UIColor(white: 0.8, alpha: 0.6)` on older systems.
    public static let background: UIColor? = {
        if #available(iOS 13.0, *) {
            return nil
        } else {
            return UIColor(white: 0.8, alpha: 0.6)
        }
    }()
}

extension HUDExtension where ExtendedType: Equatable {
    public func notEqual(_ value: ExtendedType, do block: @autoclosure() -> Void?) {
        guard type != value else { return }
        block()
    }
}
extension HUDExtension where ExtendedType: Equatable, ExtendedType: NSObjectProtocol {
    public func notEqual(_ value: ExtendedType?, do block: @autoclosure() -> Void?) {
        guard type != value, type.isEqual(value) == false else { return }
        block()
    }
}

extension HUDExtension where ExtendedType: AnyObject {
    /// Executes the given block passing the `Self` in as its sole argument.
    ///
    /// - Parameter populator: A block or function that populates the `Self`, which is passed into the block as an argument.
    /// - Note: This method is recommended for assigning values to properties.
    @discardableResult
    public func then(_ populator: (ExtendedType) throws -> Void) rethrows -> ExtendedType {
        try populator(type)
        return type
    }
}

extension HUDExtension where ExtendedType: Any {
    /// Executes the given block passing the `Self` in as its sole `inout` argument.
    ///
    /// - Parameter populator: A block or function that populates the `Self`, which is passed into the block as an `inout` argument.
    /// - Note: This method is recommended for assigning values to properties.
    @discardableResult
    public mutating func `do`(_ populator: (inout ExtendedType) throws -> Void) rethrows -> ExtendedType {
        try populator(&type)
        return type
    }
}
