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
final class PrayerThread {
	var title: String
	var creationDate: Date
	/// All prayer recordings in this thread
	///
	/// - Note: This is private because these are not guaranteed to be chronological. Use the chronologicalRecording property instead
	@Relationship(deleteRule: .cascade, inverse: \PrayerRecording.prayerThread)
	private var recordings: [PrayerRecording]

	init(title: String = "", creationDate: Date = Date()) {
		self.title = title
		self.creationDate = creationDate
		self.recordings = []
	}
}

extension PrayerThread: Hashable { }

extension PrayerThread {
	
	// MARK: Methods
	
	func addRecording(_ recording: PrayerRecording) {
		self.recordings.append(recording)
	}
}

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
	
	/// The date this prayer thread was updated
	var editedDate: Date {
		return self.recordings.last?.timestamp ?? self.creationDate
	}
	
	// Sorts recordings from oldest to newest based on timestamp
	var chronologicalRecordings: [PrayerRecording] {
		recordings.sorted(by: { $0.timestamp < $1.timestamp })
	}
	
	/// The PrayerThread has not been edited yet
	/// - Returns: Whether the prayer thread is empty or not
	var isEmpty: Bool {
		!self.hasTitle && self.count == 0
	}
	
	/// Deletes the recording files for all recordings in this thread.
	///
	/// - Warning: This cannot be undone
	func deleteAllRecordingFiles() throws {
		var errors: [Error] = []
		for recording in recordings {
			do {
				try recording.deleteRecordingFile()
			} catch {
				errors.append(error)
			}
		}
		if !errors.isEmpty {
			throw PrayerThreadError.failedToDeleteRecordingFiles(errors)
		}
	}
}

private extension PrayerThread {
	enum PrayerThreadError: LocalizedError {
		case failedToDeleteRecordingFiles([Error])
		
		var errorDescription: String? {
			switch self {
			case .failedToDeleteRecordingFiles(let errors):
				return "Failed to delete recording files:\n\(errors.map(\.localizedDescription).joined(separator: "\n"))"
			}
		}
	}
}
