//
//  Progressive.swift
//  HUD
//
//  Created by Liam on 2021/7/9.
//  Copyright (c) 2021 Liam. All rights reserved.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//


import CoreGraphics

public protocol Progressive: AnyObject {
    var progress: CGFloat { get set }
}
