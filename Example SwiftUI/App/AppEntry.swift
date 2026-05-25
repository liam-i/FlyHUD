//
//  AppEntry.swift
//  Example SwiftUI
//
//  Created by Liam on 07/09/2021.
//  Copyright (c) 2021 Liam. All rights reserved.
//

import SwiftUI

@main
struct AppEntry: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentListView()
            }
        }
    }
}
