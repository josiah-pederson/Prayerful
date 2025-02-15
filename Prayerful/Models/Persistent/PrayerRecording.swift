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
final class PrayerRecording {
	private var filePath: String
	var duration: TimeInterval
	var timestamp: Date
	var prayerThread: PrayerThread?

	init(url: URL, duration: TimeInterval, timestamp: Date = Date()) {
		self.filePath = url.relativePath
		self.duration = duration
		self.timestamp = timestamp
	}
	
	init(filePath: String, duration: TimeInterval, timestamp: Date = Date()) {
		self.filePath = filePath
		self.duration = duration
		self.timestamp = timestamp
	}
}

extension PrayerRecording: Hashable { }

extension PrayerRecording {
	var url: URL {
		return fileFinder.recordingURL(forRelativePath: filePath)
	}
	
	/// Deletes the audio recording file of this recorded prayer
	///
	/// - Warning: This cannot be undone
	func deleteRecordingFile() throws {
		try fileFinder.deleteFile(at: self.filePath)
	}
	
	func playable() throws -> PlayablePrayer {
		try .init(at: url, duration: duration)
	}
}
