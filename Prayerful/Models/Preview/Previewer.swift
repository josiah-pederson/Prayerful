//
//  Previewer.swift
//  Prayerful
//
//  Created by Josiah Pederson on 11/7/24.
//

import Foundation
import SwiftData

@MainActor
struct Previewer {
	let container: ModelContainer
	let thread: PrayerThread
	
	init() throws {
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		container = try ModelContainer(for: PrayerThread.self, configurations: config)
		
		thread = .init()
		
		container.mainContext.insert(thread)
	}
}
