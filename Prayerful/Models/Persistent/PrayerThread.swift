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

	init(title: String = "", creationDate: Date = Date()) {
		self.title = title
		self.creationDate = creationDate
		self.recordings = []
	}
}

extension PrayerThread: Hashable { }

extension PrayerThread {
	
	// MARK: Computed properties
	
	/// Duration of all Thread's recordings combined
	var duration: TimeInterval {
		recordings.reduce(0) { $0 + $1.duration }
	}
	
	/// Number of recordings in this prayer thread
	var count: Int {
		recordings.count
	}
	
	/// Indicates if this PrayerThread has been titled yet
	var hasTitle: Bool {
		!self.title.isEmpty
	}
	
	/// Puts the thread duration in a readable format such as 3 minutes
	var durationDescription: String {
		let durationInSeconds = Int(duration)
		
		let hours = durationInSeconds / 3600
		let minutes = (durationInSeconds % 3600) / 60
		let seconds = durationInSeconds % 60
		
		if hours > 0 {
			return "\(hours) hour\(hours > 1 ? "s" : "")"
		} else if minutes > 0 {
			return "\(minutes) minute\(minutes != 1 ? "s" : "")"
		} else {
			return "\(seconds) second\(seconds != 1 ? "s" : "")"
		}
	}
}
