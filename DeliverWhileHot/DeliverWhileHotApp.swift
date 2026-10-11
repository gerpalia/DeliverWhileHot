//
//  DeliverWhileHotApp.swift
//  DeliverWhileHot
//
//  Created by Gerson on 23/9/26.
//

import SwiftUI

@main
struct DeliverWhileHotApp: App {
    init() {
        DiagnosticsReporter.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}
