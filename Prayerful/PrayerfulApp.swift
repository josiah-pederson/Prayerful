//
//  PrayerfulApp.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/28/24.
//

import SwiftUI
import SwiftData

@main
struct PrayerfulApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
		// Initialize persistent storage
		.modelContainer(for: PrayerThread.self)
    }
}
