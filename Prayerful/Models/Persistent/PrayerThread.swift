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
	
	/// Duration of all Thread's recordings combined
	var duration: TimeInterval {
		recordings.reduce(0) { $0 + $1.duration }
	}
	
	/// Number of recordings in this prayer thread
	var count: Int {
		recordings.count
	}
	
	var hasTitle: Bool {
		!self.title.isEmpty
	}

	init(title: String = "", creationDate: Date = Date()) {
		self.title = title
		self.creationDate = creationDate
		self.recordings = []
	}
}

extension PrayerThread: Hashable { }
