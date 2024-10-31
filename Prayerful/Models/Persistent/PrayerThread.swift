//
//  PrayerThread.swift
//  Prayerful
//
//  Created by Josiah Pederson on 10/29/24.
//

import Foundation
import SwiftData

/// A thread of prayer recordings about a topic
///
/// Uses the ``PrayerRecording`` model for saving recordings
///
/// - Note: This is a SwiftData persistent storage model
@Model
class PrayerThread {
	var title: String
	var creationDate: Date
	@Relationship(deleteRule: .cascade, inverse: \PrayerRecording.prayerThread)
	var recordings: [PrayerRecording]

	init(title: String, creationDate: Date = Date()) {
		self.title = title
		self.creationDate = creationDate
		self.recordings = []
	}
}
