//
//  PrayerRecording.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/29/24.
//

import Foundation
import SwiftData

/// A recording of a prayer as part of a ``PrayerThread``
///
/// - Note: This is a SwiftData persistent storage model
@Model
class PrayerRecording {
	var filePath: URL
	var duration: Double
	var timestamp: Date
	var prayerThread: PrayerThread?

	init(filePath: URL, duration: Double, timestamp: Date = Date()) {
		self.filePath = filePath
		self.duration = duration
		self.timestamp = timestamp
	}
}
